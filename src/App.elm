module App exposing (..)

import Html exposing (Html, text, div, img)
import Http
import Json.Decode as Decode


type alias Model =
    { available : Int
    , locks : Int
    }


init : String -> ( Model, Cmd Msg )
init flags =
    ( { available = 0, locks = 0 }
    , getStatus
    )


type Msg
    = NoOp
    | Alive (Result Http.Error Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Alive (Ok res) ->
            ( { model | available = res.available, locks = res.locks }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        Alive (Err _) ->
            ( model, Cmd.none )


getStatus : Cmd Msg
getStatus =
    let
        url =
            "http://localhost:3001/available"
    in
        Http.send Alive
            (Http.get url decodeResponse)


decodeResponse : Decode.Decoder Model
decodeResponse =
    Decode.map2
        Model
        (Decode.at [ "availability", "bikes" ] Decode.int)
        (Decode.at [ "availability", "locks" ] Decode.int)


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text ("Available: " ++ (toString model.available)) ]
        , div [] [ text ("Locks: " ++ (toString model.locks)) ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
