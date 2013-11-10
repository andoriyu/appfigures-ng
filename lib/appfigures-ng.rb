require_relative 'appfigures-ng/version'
require_relative 'appfigures-ng/connection'

require 'date'

class Appfigures
  attr_reader :connection
 
  TIME_FORMAT     = '%Y-%m-%d'
  COUNTRIES_LIST  = ["AE", "AG", "AI", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BB", "BE", "BF", "BG", "BH", "BJ", "BM", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CG", "CH", "CL", "CN", "CO", "CR", "CV", "CY", "CZ", "DE", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GB", "GD", "GH", "GM", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KN", "KR", "KW", "KY", "KZ", "LA", "LB", "LC", "LK", "LR", "LT", "LU", "LV", "MD", "MG", "MK", "ML", "MN", "MO", "MR", "MS", "MT", "MU", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PT", "PW", "PY", "QA", "RO", "RU", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SN", "SR", "ST", "SV", "SZ", "TC", "TD", "TH", "TJ", "TM", "TN", "TR", "TT", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VE", "VG", "VN", "YE", "ZA", "ZW"] 
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
          date:             Date.parse(report['date']),
          product_id:       report['product_id'].to_s,
          downloads:        report['downloads'],
          net_downloads:    report['net_downloads'],
          updates:          report['updates'],
          revenue:          report['revenue'].to_f,
          gift_redeptions:  report['gift_redeptions'],
          promos:           report['promos']
        })
      end
    end
    return reports
  end

  def ranks_report(start_date:nil, end_date:nil, granularity: :daily, products: nil, countries: :all)
    options = {}
    options['start_date']    = start_date.is_a?(Date) ? start_date : raise(ArgumentError, 'start_date has to be a Date')
    options['end_date']      = end_date.is_a?(Date) ? end_date :  raise(ArgumentError, 'end_date has to be a Date')
    options['granularity']   = [:daily, :hourly].include?(granularity) ? granularity : raise(ArgumentError, 'granularity has be either :daily or :hourly')
    options['products']      = products.is_a?(Array) ? products.join(';') : products.is_a?(String) ? products : raise(ArgumentError, 'products has to be specified')
    params  = {}
    params['countries']      = countries == :all ? COUNTRIES_LIST.join(';') : countries.is_a?(Array) ? countries.join(';') : "US"
    res = self.connection.get("ranks/#{options['products']}/#{options['granularity']}/#{options['start_date']}/#{options['end_date']}", params).body
    position_legend = res['dates']
    reports = []
    ids_in_report = res['data'].map{|e|e['product_id']}.uniq
    ids_in_report.each do |id|
      data = []
      res['data'].select{|e| e['product_id'] == id}.each do |app_report|
        app_report['positions'].each_with_index do |position, index|
          data << Hashie::Mash.new({
            product_id: id.to_s,
            country: app_report['country'],
            store:  app_report['category']['store'],
            category: app_report['category']['name'],
            sub_type: app_report['category']['subtype'],
            device: app_report['category']['device'],
            position: position,
            delta:  app_report['deltas'][index],
            date: Date.parse(position_legend[index])
          })
        end
      end
      reports << Hashie::Mash.new({
        product_id: id.to_s,
        reports: data
      })
    end
    return reports
  end

  def list_of_countries
    self.connection.get('data/countries/apple').body.map {|k,v| k}
  end
end

