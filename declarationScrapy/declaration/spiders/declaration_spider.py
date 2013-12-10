from scrapy.contrib.spiders import CrawlSpider, Rule
from scrapy.spider import BaseSpider
from scrapy.contrib.linkextractors.sgml import SgmlLinkExtractor
from scrapy.item import Item
from scrapy.http import Request
from declaration.items import MyItem
import subprocess

class DeclarationSpider(BaseSpider):
    name = 'declaration'
    allowed_domains = ['declaration.gov.ge']

    def start_requests(self):
        f = open("idlist")
        for idurl in f.readlines():
            url = 'https://declaration.gov.ge/eng/declaration?id=' + idurl.strip()
            yield Request(url, self.parse)
            url = 'https://declaration.gov.ge/declaration?id=' + idurl.strip()
            yield Request(url, self.parse)
        f.close()

    def parse(self, response):
	i = MyItem()
        currenturl = response.url
        pdfid = currenturl.split('=')[1]
        i['body'] = response.body
        i['url'] = currenturl
        i['pdfid'] = pdfid
        if currenturl.find("eng") == -1:
            i['lang'] = 'ka'
        else:
            i['lang'] = 'en'
        return i

