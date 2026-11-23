require "rails_helper"

RSpec.describe AgeCalculator do
  describe ".years" do
    it "counts a birthday from its day" do
      expect(described_class.years("2270-05-10", "2300-05-09")).to eq(29)
      expect(described_class.years("2270-05-10", "2300-05-10")).to eq(30)
      expect(described_class.years("2270-05-10", "2300-05-11")).to eq(30)
    end

    it "compares months before days" do
      expect(described_class.years("2270-05-10", "2300-04-30")).to eq(29)
      expect(described_class.years("2270-05-10", "2300-06-01")).to eq(30)
    end

    it "counts a 29 February birthday from 1 March in other years" do
      expect(described_class.years("2272-02-29", "2300-02-28")).to eq(27)
      expect(described_class.years("2272-02-29", "2300-03-01")).to eq(28)
      expect(described_class.years("2272-02-29", "2296-02-29")).to eq(24)
    end

    it "is never below 0" do
      expect(described_class.years("2270-05-10", "2260-01-01")).to eq(0)
      expect(described_class.years("2270-05-10", "2270-05-09")).to eq(0)
    end

    it "handles years before 1582" do
      expect(described_class.years("1000-01-01", "1582-10-10")).to eq(582)
      expect(described_class.years("1499-03-01", "1500-02-28")).to eq(0)
      expect(described_class.years("0001-01-01", "0100-01-01")).to eq(99)
    end
  end

  describe ".range" do
    it "shows one age without an end date or without a change" do
      expect(described_class.range("2270-05-10", "2300-01-01", nil)).to eq("29")
      expect(described_class.range("2270-05-10", "2300-01-01", "2300-05-09")).to eq("29")
    end

    it "shows both ages with an en dash" do
      expect(described_class.range("2270-05-10", "2300-01-01", "2302-05-10")).to eq("29–32")
    end
  end

  describe ".on" do
    def age(years, deceased)
      described_class::Age.new(years:, deceased:)
    end

    it "is living without a death date or before it" do
      expect(described_class.on("2270-05-10", "2300-05-10")).to eq(age(30, false))
      expect(described_class.on("2270-05-10", "2300-05-10", "2301-01-01")).to eq(age(30, false))
    end

    it "is living on the day of death" do
      expect(described_class.on("2270-05-10", "2300-05-10", "2300-05-10")).to eq(age(30, false))
    end

    it "keeps the age at death afterward" do
      expect(described_class.on("2270-05-10", "2310-01-01", "2300-05-09")).to eq(age(29, true))
    end
  end
end
