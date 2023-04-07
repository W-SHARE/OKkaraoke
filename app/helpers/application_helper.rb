module ApplicationHelper
    def default_meta_tags
        {
          site: 'OKカラオケ',
          title: 'OKカラオケ',
          reverse: true,
          charset: 'utf-8',
          description: '近くのカラオケ店舗の料金を自動で算出します。',
          keywords: 'カラオケ',
          canonical: request.original_url,
          separator: '|',
          icon: [
            { href: image_url('favicon.ico') },
            { href: image_url('iosHomeIcon.png'), rel: 'apple-touch-icon', sizes: '180x180', type: 'image/png' },
            { href: image_url('iosHomeIcon.png'), rel: 'android-touch-icon', sizes: '192x192', type: 'image/png' },
          ],
          og: {
            site_name: :site, # もしくは site_name: :site
            title: :title, # もしくは title: :title
            description: :description, # もしくは description: :description
            type: 'website',
            url: request.original_url,
            image: image_url('top-logo.png'),
            locale: 'ruby',
          },
          twitter: {
            card: 'summary',
            site: '@waseda_share',
          }
        }
      end
end
