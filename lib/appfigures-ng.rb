require_relative 'appfigures-ng/version'
require_relative 'appfigures-ng/connection'

class Appfigures
  attr_reader :connection
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
end
