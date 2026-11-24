module Api
  class SummariesController < BaseController
    def show
      ids = query("characterIds").to_s.split(",").filter_map { |text| leading_integer(text) }.select(&:positive?)
      render plain: SummaryOperation.text(ids)
    end
  end
end
