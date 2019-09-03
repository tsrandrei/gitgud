defmodule GitGud.Web.DateTimeFormatterTest do
  use ExUnit.Case, async: true
  use Timex

  import GitGud.Web.DateTimeFormatter

  test "formats date" do
    assert datetime_format_str(~D[2018-10-16], "{YYYY}-{M}-{D}") == "2018-10-16"
  end

  test "formats time" do
    assert datetime_format_str(~T[00:28:07], "{h24}:{m}") == "00:28"
  end

  test "formats relative timestamps" do
    date = Timex.now()
    assert datetime_format_str(date, "{relative}") == "now"
    assert datetime_format_str(Timex.shift(date, minutes: -35), "{relative}") == "35 minutes ago"
    assert datetime_format_str(Timex.shift(date, hours: -4), "{relative}") == "4 hours ago"
    assert datetime_format_str(Timex.shift(date, days: -7), "{relative}") == "7 days ago"
    assert datetime_format_str(Timex.shift(date, days: -70), "{relative}") == "2 months ago"
    assert datetime_format_str(Timex.shift(date, years: -1), "{relative}") == "1 year ago"
  end
end
