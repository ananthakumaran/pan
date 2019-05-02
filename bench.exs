NimbleCSV.define(TripParser, separator: ",", escape: "\"")

defmodule Trip do
  use Pan.Automata
  import Mex

  mex do
    automata :long,
      contiguity: :skip_till_next_match,
      pattern: [trip :: a, trip :: b, trip :: c],
      partition_by: [:medallion],
      within: 86400,
      where:
        a.medallion == b.medallion && b.medallion == c.medallion &&
          a.trip_time_in_secs > 60 * 60 * 1 && b.trip_time_in_secs > 60 * 60 * 1 &&
          c.trip_time_in_secs > 60 * 60 * 1
  end
end

"~/data/trip/trip_data_small_sorted.csv"
|> Path.expand()
|> File.stream!(read_ahead: 1024 * 1024)
|> TripParser.parse_stream()
|> Stream.map(fn [
                   medallion,
                   hack_license,
                   vendor_id,
                   rate_code,
                   store_and_fwd_flag,
                   pickup_datetime,
                   dropoff_datetime,
                   passenger_count,
                   trip_time_in_secs,
                   trip_distance,
                   pickup_longitude,
                   pickup_latitude,
                   dropoff_longitude,
                   dropoff_latitude
                 ] ->
  {trip_time_in_secs, ""} = Integer.parse(trip_time_in_secs)

  pickup_epoch =
    NaiveDateTime.from_iso8601!(pickup_datetime)
    |> NaiveDateTime.diff(~N[1970-01-01 00:00:00])

  %{
    medallion: medallion,
    hack_license: hack_license,
    vendor_id: vendor_id,
    rate_code: rate_code,
    store_and_fwd_flag: store_and_fwd_flag,
    pickup_datetime: pickup_datetime,
    pickup_epoch: pickup_epoch,
    dropoff_datetime: dropoff_datetime,
    passenger_count: passenger_count,
    trip_time_in_secs: trip_time_in_secs,
    trip_distance: trip_distance,
    pickup_longitude: pickup_longitude,
    pickup_latitude: pickup_latitude,
    dropoff_longitude: dropoff_longitude,
    dropoff_latitude: dropoff_latitude
  }
end)
|> Enum.reduce(Trip.long(), fn trip, state ->
  state = Trip.long(trip, state, trip.pickup_epoch)

  if !Enum.empty?(state.matches) do
    Enum.each(state.matches, &IO.inspect/1)
    %{state | matches: []}
  else
    state
  end
end)
