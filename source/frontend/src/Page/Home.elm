module Page.Home exposing (Model, Msg, init, subscriptions, toSession, update, view)

{-| The homepage. You can get here via either the / or /#/ routes.
-}

import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (class, value, src, style)
import Html.Events exposing (onInput)

import Session exposing (Session)
import Route exposing (Route)
import Task exposing (Task)

import Browser exposing (sandbox)
import Http exposing (Error(..))
import Json.Decode as Decode exposing (Decoder, int, string, field)

-- MODEL

type alias Model =
    { 
        session : Session
        , images: List Image
        , error : Maybe String
    }

type alias Image =
    { id : Int
    , name : String
    , description : String
    , image_original_url : String
    }


decodeImage : Decoder Image
decodeImage =
   Decode.map4 Image
     (Decode.field "id" Decode.int)
     (Decode.field "name" Decode.string)
     (Decode.field "description" Decode.string)
     (Decode.field "image_original_url" Decode.string)

type Msg
    = GotImages (Result Http.Error (List Image))

init : Session -> ( Model, Cmd Msg )
init session =
    (
    { 
        session = session
        , images = []
        , error = Nothing
    }
    , getImages
    )
getImages : Cmd Msg
getImages =
    Http.get
        { url = "http://localhost:4000/api/image"
        , expect = Http.expectJson GotImages (Decode.field "data" (Decode.list decodeImage))
        }


-- VIEW

view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Home"
    , content =      
        let
            nb_image = List.length model.images
            
        in
            div [class "home-page"] [
                div [ class "container page" ] [
                    div [ class "images-list" ] [ 
                        if nb_image == 0 then
                            text "Loading…"

                        else
                            case model.error of
                                Nothing ->
                                    div [class "list-images"]
                                        [ List.take 100 model.images
                                            |> List.map viewImage
                                            |> div []
                                        ]

                                Just error ->
                                    div [ ]
                                        [ h1 [] [ text error ] ]
                        ]
                ]
            ]
    }

viewImage : Image -> Html Msg
viewImage image =
    a [class "image-card", style "background-image" ("url(\"http://localhost:4000" ++ (image.image_original_url ++ "\")")), Route.href (Route.ImageById image.id)] []

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotImages (Ok images) ->
            ( { model
                | images = images
                , error = Nothing
              }
            , Cmd.none
            )

        GotImages (Err err) ->
            let
                _ =
                    Debug.log "An error occured" err
            in
            ( { model
                | error = Just <| errorToString err
                , images = []
              }
            , Cmd.none
            )


-- HTTP

scrollToTop : Task x ()
scrollToTop =
    Dom.setViewport 0 0
        -- It's not worth showing the user anything special if scrolling fails.
        -- If anything, we'd log this to an error recording service.
        |> Task.onError (\_ -> Task.succeed ())

errorToString : Http.Error -> String
errorToString error =
    case error of
        BadUrl url ->
            "Bad url: " ++ url

        Timeout ->
            "Request timed out."

        NetworkError ->
            "Network error. Are you online?"

        BadStatus status_code ->
            "HTTP error " ++ String.fromInt status_code

        BadBody body ->
            "Unable to parse response body: " ++ body



-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- EXPORT

toSession : Model -> Session
toSession model =
    model.session