package main

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/chromedp/cdproto/browser"
	"github.com/chromedp/chromedp"
	"golang.org/x/sync/errgroup"
)

func main() {
	if err := run(); err != nil {
		panic(err)
	}
}

func run() error {
	ctx, cancel := chromedp.NewContext(context.Background())
	defer cancel()

	err := chromedp.Run(ctx,
		browser.SetDownloadBehavior(browser.SetDownloadBehaviorBehaviorAllow).
			WithDownloadPath("."),
	)
	if err != nil {
		return fmt.Errorf("failed to set download behavior: %w", err)
	}

	var urlLoc string
	// Handle login
	err = Login(ctx, &urlLoc)
	if err != nil {
		return err
	}

	// Extract base URL and page number
	sepPos := strings.LastIndex(urlLoc, "/")
	url := urlLoc[:sepPos]
	page, err := strconv.Atoi(urlLoc[sepPos+1:])
	if err != nil {
		return err
	}

	numberOfCheckedPages := 3
	var eg errgroup.Group
	for i := range numberOfCheckedPages {
		eg.Go(func() error {
			return extractAttachmentsFromPage(ctx, url, page, i)
		})
	}
	if err := eg.Wait(); err != nil {
		return err
	}

	return nil
}

func Login(ctx context.Context, urlLoc *string) error {
	if err := chromedp.Run(
		ctx,
		chromedp.Navigate("https://abv.bg"),

		// close consent banner
		chromedp.Click(".fc-cta-consent", chromedp.ByQuery),

		// login
		chromedp.SendKeys("#username", os.Getenv("USERNAME"), chromedp.ByID),
		chromedp.SendKeys("#password", os.Getenv("PASSWORD"), chromedp.ByID),
		chromedp.Submit("#loginForm", chromedp.ByID),

		// click forward button
		chromedp.Submit("#loggedUser", chromedp.ByID),
		chromedp.Sleep(1*time.Second),
		chromedp.Click(`//div[contains(text(), 'UBB')]`, chromedp.BySearch),
		chromedp.Sleep(100*time.Millisecond),
		chromedp.Location(urlLoc),
	); err != nil {
		return err
	}
	return nil
}

func extractAttachmentsFromPage(ctx context.Context, url string, page int, i int) error {
	tabCtx, cancel := chromedp.NewContext(ctx)
	defer cancel()

	// Find unflagged emails
	unflaggedEmails := make([]bool, 35)
	tmpRes := make([]byte, 4)
	var nodesCount int
	unflaggedCount := 0
	pageUrl := fmt.Sprintf("%s/%d", url, page+i)

	// Getting unflagged emails
	if err := chromedp.Run(
		tabCtx,
		chromedp.Navigate(pageUrl),
		chromedp.Sleep(5*time.Second),
		chromedp.Evaluate(`document.querySelectorAll("tr:has(.abv-mailSubject)").length`, &nodesCount),
		chromedp.ActionFunc(func(ctx context.Context) error {
			for i := 0; i < nodesCount; i++ {
				if err := chromedp.Evaluate(fmt.Sprintf(`document.querySelectorAll("tr:has(.abv-mailSubject)")[%d].querySelector(".icon-flag-on")`, i), &tmpRes).Do(ctx); err != nil {
					fmt.Println(err)
					continue
				}
				if tmpRes[0] != 'n' {
					continue
				}
				unflaggedEmails[i] = true
				unflaggedCount++
			}
			return nil
		}),
	); err != nil {
		return err
	}

	// Exit early if there are no unflagged emails
	if unflaggedCount == 0 {
		return nil
	}

	delayBetweenActions := 1 * time.Second
	for unflaggedCount > 0 {
		for i := 0; i < nodesCount; i++ {
			if !unflaggedEmails[i] {
				continue
			}

			err := extractAttachmentsFromEmail(tabCtx, i, pageUrl, delayBetweenActions)
			if err != nil {
				return err
			}
			unflaggedCount--
			unflaggedEmails[i] = false
		}
	}
	return nil
}

func extractAttachmentsFromEmail(tabCtx context.Context, i int, pageUrl string, delayBetweenActions time.Duration) error {
	flagSelector := fmt.Sprintf(`tr:has(.abv-mailSubject):nth-child(%d) .icon-flag-off`, i+1)
	zipSelector := "span[title]"
	mailSelector := fmt.Sprintf("tbody:has(.abv-mailSubject)  > tr:nth-of-type(%d) > td:nth-of-type(2)", i+1)

	scrShot := make([]byte, 0, 4096)

	return chromedp.Run(
		tabCtx,
		chromedp.Navigate(pageUrl),
		chromedp.Sleep(delayBetweenActions),

		// Flagging
		chromedp.WaitReady(flagSelector, chromedp.ByQuery),
		chromedp.Click(flagSelector, chromedp.ByQuery),
		chromedp.Sleep(delayBetweenActions),

		// Opening email
		chromedp.WaitReady(mailSelector, chromedp.ByQuery),
		chromedp.Click(mailSelector, chromedp.ByQuery),
		chromedp.Sleep(delayBetweenActions),
		chromedp.FullScreenshot(&scrShot, 100),

		// Downloading attachment
		chromedp.WaitReady(zipSelector, chromedp.ByQuery),
		chromedp.Click(zipSelector, chromedp.ByQuery),
		chromedp.Sleep(delayBetweenActions),
	)
}
