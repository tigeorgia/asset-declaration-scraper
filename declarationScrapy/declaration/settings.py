# Scrapy settings for declaration project
#
# For simplicity, this file contains only the most important settings by
# default. All the other settings are documented here:
#
#     http://doc.scrapy.org/en/latest/topics/settings.html
#

BOT_NAME = 'declaration'

SPIDER_MODULES = ['declaration.spiders']
NEWSPIDER_MODULE = 'declaration.spiders'

ITEM_PIPELINES = [
    'declaration.pipelines.DeclarationPipeline'
]

# Crawl responsibly by identifying yourself (and your website) on the user-agent
#USER_AGENT = 'declaration (+http://www.yourdomain.com)'
