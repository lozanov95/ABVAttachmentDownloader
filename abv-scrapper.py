from typing import Optional, Tuple
from selenium.webdriver.common.by import By
from selenium.webdriver import Chrome
from selenium.webdriver.remote.webelement import WebElement
from selenium.webdriver.chrome.service import Service
from selenium.common.exceptions import (
    NoSuchElementException,
    StaleElementReferenceException,
)
from getpass import getpass
import time
import logging


class ABVAttachmentDownloader:
    def __init__(
        self,
        webdriver_path: str = r"C:\chromedriver.exe",
        folder_name: str = "UBB",
        log_level: str = "INFO",
    ) -> None:
        """Downloads the attachments from a given folder."""
        self.webdriver_path = webdriver_path
        self.url = "https://abv.bg"
        self.folder_name = folder_name
        self.load_timeout = 2
        self.logger = self._get_logger(log_level=log_level)

    def _get_logger(self, log_level: str):
        """Configures and returns a logger instance."""
        FORMAT = "%(asctime)s %(module)s [%(levelname)s]: %(message)s"
        logging.basicConfig(level=log_level.upper(), format=FORMAT)
        return logging.getLogger(__name__)

    def _get_credentials(self) -> Tuple[str, str]:
        """Gets the credentials from a user. Returns tuple(username, password)."""
        username = input("Username: ")
        password = getpass("Password: ")

        return username, password

    def _consent_cookies(self, browser: Chrome) -> None:
        """Closes the consent modal."""
        browser.execute_script("document.querySelector('#abv-GDPR-frame').remove()")
        self.logger.info("Closed GDPR consent modal.")

    def _sign_in(self, browser: Chrome, credentials: Tuple[str, str]):
        """Signs in with the given credentials."""
        username, password = credentials
        browser.find_element(by=By.ID, value="username").send_keys(username)
        browser.find_element(by=By.ID, value="password").send_keys(password)
        browser.find_element(by=By.ID, value="loginBut").submit()
        self.logger.info(f"Signed in with account {username}.")

    def _open_folder(self, browser: Chrome, folder_name: str) -> None:
        """Opens a given folder."""
        folders = browser.find_elements(by=By.CLASS_NAME, value="foldersRow")
        for folder in folders:
            if folder_name in folder.text:
                return folder.click()

    def _find_flag(self, browser) -> Optional[WebElement]:
        """Finds an unclicked flag and returns it as an instance."""
        try:
            return browser.find_element(by=By.CSS_SELECTOR, value=".icon-flag-off")
        except NoSuchElementException as e:
            self.logger.info("No more unflagged emails found.")
            return None

    def _get_row_number(self, flag: WebElement) -> str:
        """Returns the number of the flag's row."""
        attributes = (
            flag.get_property("parentElement")
            .get_property("parentElement")
            .get_property("parentElement")
            .get_property("attributes")
        )

        for attribute in attributes:
            if attribute.get("name") == "__gwt_row":
                return attribute.get("nodeValue")

    def _select_email(self, browser: Chrome) -> bool:
        """Finds non-flagged email and opens it."""
        time.sleep(self.load_timeout)
        flag = self._find_flag(browser=browser)

        if not flag:
            return False

        row_number = self._get_row_number(flag)
        flag.click()

        browser.find_element(
            by=By.CSS_SELECTOR, value=f'[__gwt_row="{row_number}"][class*="GG"]'
        ).find_element(by=By.CSS_SELECTOR, value=".inbox-cellTableSecondColumn").click()

        return True

    def _download_attachment(self, browser: Chrome) -> None:
        """Downloads attachments from an email."""
        download_links = browser.find_elements(
            by=By.CSS_SELECTOR, value=".attachmentDownload"
        )
        for link in download_links:
            parent_div: WebElement = link.get_property("parentNode")
            file_text: str = parent_div.get_property("children")[0].text
            if ".p7s" in file_text.lower():
                logging.debug("Skipped .p7s file.")
                continue
            link.click()
            file_text = file_text.replace("\n", " ")
            self.logger.info(f"Downloaded file {file_text}.")

    def _download_attachments(self, browser: Chrome):
        """Downloads attachments."""
        while True:
            try:
                self._open_folder(browser=browser, folder_name=self.folder_name)
                if not self._select_email(browser=browser):
                    return
                self._download_attachment(browser=browser)
            except StaleElementReferenceException as e:
                self.logger.error(e)

    def download(self):
        """Downloads attachments from the ABV.bg mailbox."""
        credentials = self._get_credentials()
        service = Service(executable_path=self.webdriver_path)

        with Chrome(service=service) as browser:
            browser.implicitly_wait(10)
            browser.get(self.url)
            self._consent_cookies(browser=browser)
            self._sign_in(browser=browser, credentials=credentials)
            self._download_attachments(browser=browser)


if __name__ == "__main__":
    scrapper = ABVAttachmentDownloader()
    scrapper.download()
