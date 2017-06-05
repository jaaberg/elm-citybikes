module App exposing (..)

import Html exposing (Html, text, div, img, span)
import Html.Attributes exposing (class)
import Http
import Json.Decode as Decode
import Time exposing (every, Time)
import Date.Extra exposing (toFormattedString)
import Date exposing (..)


type alias Model =
    { cityBikeStations : List CityBikeStation
    , busStations : List BusStation
    }


type alias CityBikeStation =
    { name : String
    , bikes : Int
    , locks : Int
    }


type alias BusStation =
    { name : String
    , departures : List BusDeparture
    }


type alias BusDeparture =
    { lineNumber : String
    , destinationName : String
    , expectedDepartureTime : Int
    }


init : String -> ( Model, Cmd Msg )
init flags =
    ( Model [] []
    , getStatus
    )


type Msg
    = NoOp
    | TrasportationResult (Result Http.Error Model)
    | GetStatus Time.Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TrasportationResult (Ok res) ->
            ( { model | cityBikeStations = res.cityBikeStations, busStations = res.busStations }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        TrasportationResult (Err _) ->
            ( model, Cmd.none )

        GetStatus time ->
            ( model, getStatus )


getStatus : Cmd Msg
getStatus =
    let
        url =
            "http://localhost:3001/publictransportation"
    in
        Http.send TrasportationResult
            (Http.get url decodeResponse)


decodeResponse : Decode.Decoder Model
decodeResponse =
    Decode.map2
        Model
        (Decode.at [ "cityBikeStations" ] decodeCityBikeStations)
        (Decode.at [ "busStations" ] decodeBusStations)


decodeBusStations : Decode.Decoder (List BusStation)
decodeBusStations =
    Decode.list decodeBusStation


decodeBusStation : Decode.Decoder BusStation
decodeBusStation =
    Decode.map2
        BusStation
        (Decode.at [ "name" ] Decode.string)
        (Decode.at [ "departures" ] (Decode.list decodeBusDepatures))


decodeBusDepatures : Decode.Decoder BusDeparture
decodeBusDepatures =
    Decode.map3
        BusDeparture
        (Decode.at [ "lineNumber" ] Decode.string)
        (Decode.at [ "destinationName" ] Decode.string)
        (Decode.at [ "expectedDepartureTime" ] Decode.int)


decodeCityBikeStations : Decode.Decoder (List CityBikeStation)
decodeCityBikeStations =
    Decode.list decodeCityBikeStation


decodeCityBikeStation : Decode.Decoder CityBikeStation
decodeCityBikeStation =
    Decode.map3
        CityBikeStation
        (Decode.at [ "name" ] Decode.string)
        (Decode.at [ "bikes" ] Decode.int)
        (Decode.at [ "locks" ] Decode.int)


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ div [] (List.map renderCityBikeStation model.cityBikeStations)
        , div [ class "bus-departures" ]
            [ div [ class "content" ] (List.map renderBusStation model.busStations)
            ]
        ]


renderCityBikeStation : CityBikeStation -> Html Msg
renderCityBikeStation cbs =
    div [ class "city-bike-station" ]
        [ div [ class "header" ] [ span [ class "header__border" ] [ text cbs.name ] ]
        , div [ class "content" ]
            [ div [] [ text ("Ledige sykler: " ++ (toString cbs.bikes)) ]
            , div [] [ text ("Ledige låser: " ++ (toString cbs.locks)) ]
            ]
        ]


renderBusStation : BusStation -> Html Msg
renderBusStation bs =
    div [ class "bus-departures" ]
        [ div [ class "header" ] [ span [ class "header__border" ] [ text bs.name ] ]
        , div [ class "content" ] (List.map renderBusDeparture bs.departures)
        ]


renderBusDeparture : BusDeparture -> Html Msg
renderBusDeparture bd =
    let
        departureTime =
            (toFormattedString "HH:mm" (Date.fromTime (toFloat bd.expectedDepartureTime)))
    in
        div []
            [ div []
                [ text (bd.lineNumber ++ " " ++ bd.destinationName ++ " ")
                , span [ class "city-bike-station--departure-time" ] [ text departureTime ]
                ]
            ]


subscriptions : Model -> Sub Msg
subscriptions model =
    every 30000 GetStatus
