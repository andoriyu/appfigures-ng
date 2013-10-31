require_relative 'appfigures-ng/version'
require_relative 'appfigures-ng/connection'

require 'date'

class Appfigures
  attr_reader :connection
 
  TIME_FORMAT = '%Y-%m-%d'
  
  def initialize(options = {})
    @connection = Appfigures::Connection.new options
  end

  def total_sales
    res = self.connection.get('sales').body
    Hashie::Mash.new({
      downloads:         res['downloads'],
      updates:           res['updates'],
      returns:           res['returns'],
      net_downloads:     res['net_downloads'],
      promos:            res['promos'],
      revenue:           res['revenue'].to_f,
      edu_downloads:     res['edu_downloads'],
      gifts:             res['gifts'],
      gifts_redemptions: res['gifts_redemptions']
    })
  end

  def sales_by_products_and_dates(start_date:nil, end_date:nil, granularity:nil, products: :all, countries: :all, include_inapps: false)
    params = {}
    params['start_date']      = start_date if start_date
    params['end_date']        = end_date if end_date
    params['granularity']     = granularity if granularity
    params['products']        = products if (products && products != :all)
    params['countries']       = countries if (countries && countries != :all)
    params['include_inapps']  = include_inapps if include_inapps
    res = self.connection.get('sales/products+dates', params).body
    reports = []
    res.each do |product_id, tail|
      tail.each do |report_date, report|
        reports << Hashie::Mash.new({
          date:             report['date'],
          product_id:       report['product_id'],
          downloads:        report['downloads'],
          net_downloads:    report['net_downloads'],
          revenue:          report['revenue'].to_f,
          gift_redeptions:  report['gift_redeptions'],
          promos:           report['promos']
        })
      end
    end
    return reports
  end
end
