package com.example.musicroom.api

data class UserRegistrationRequest(
    val username: String,
    val email: String,
    val password: String
)

data class UserLoginRequest(
    val username: String,
    val password: String
)

data class LogoutRequest(
    val username: String
)

data class UserDto(
    val id: Int,
    val username: String,
    val email: String
)

data class UserAuthResponse(
    val token: String,
    val user: UserDto
)

data class ContributorsDto(
    val ,
      "id": 27,
      "name": "Daft Punk",
      "link": "https://www.deezer.com/artist/27",
      "share": "https://www.deezer.com/artist/27?utm_source=deezer&utm_content=artist-27&utm_term=0_1745657513&utm_medium=web",
      "picture": "https://api.deezer.com/artist/27/image",
      "picture_small": "https://cdn-images.dzcdn.net/images/artist/b9eef585fd41e2e8813753f047b60036/56x56-000000-80-0-0.jpg",
      "picture_medium": "https://cdn-images.dzcdn.net/images/artist/b9eef585fd41e2e8813753f047b60036/250x250-000000-80-0-0.jpg",
      "picture_big": "https://cdn-images.dzcdn.net/images/artist/b9eef585fd41e2e8813753f047b60036/500x500-000000-80-0-0.jpg",
      "picture_xl": "https://cdn-images.dzcdn.net/images/artist/b9eef585fd41e2e8813753f047b60036/1000x1000-000000-80-0-0.jpg",
      "radio": true,
      "tracklist": "https://api.deezer.com/artist/27/top?limit=50",
      "type": "artist",
      "role": "Main"
)

data class DeezerTrackResponse(
    val id: Int,
    val readable: Boolean,
    val title: String,
    val title_short: String,
    val title_version: String,
    val isrc: String,
    val link: String,
    val share: String,
    val duration: Int,
    val track_position: Int,
    val disk_number: Int,
    val rank: Int,
    val release_date: String,
    val explicit_lyrics: Boolean,
    val explicit_content_lyrics: Int,
    val explicit_content_cover: Int,
    val preview: String,
    val bpm: Int,
    val gain: Float,
    val available_countries: Array<String>,
    val contributors: Array<ContributorsDto>,
  "md5_image": "5718f7c81c27e0b2417e2a4c45224f8a",
  "track_token": "AAAAAWgMnqloDbfpUz5i5fd9NlGkv1czqzhvfXc1Y2Q6WBI4uYHh0tqkz8YBXTIJ24wcgWJ5_58R35MMh_hmqLxbTNUw45IMzHSmu-Y2uSTgAntrVkCXN4IerI5bhMzuT523OYGFYI2Bpn-7AU9y_OHMjGvWBLL0Ezz9xnCehDiHkwLfLmvlKNMFzO17T1G7t7_yp4Jxlrjs0af_bWaoNEYJPkZ7RdwpgBf_Qlg6h-KMTsybmjcf0BeuV2eqMU9iMipIhyGdyQsO1X9gnmA16CvTgfNG_VFoa1l2A1gjijxFBMzsheZccNHjx9jM7zpnVdHv-S5L4zdNNiWi_5ORl693nX3zz97jZ7k",
  "artist": {
    "id": 27,
    "name": "Daft Punk",
    "link": "https://www.deezer.com/artist/27",
    "share": "https://www.deezer.com/artist/27?utm_source=deezer&utm_content=artist-27&utm_term=0_1745657513&utm_medium=web",
    "picture": "https://api.deezer.com/artist/27/image",
    "picture_small": "https://cdn-images.dzcdn.net/images/artist/b9eef585fd41e2e8813753f047b60036/56x56-000000-80-0-0.jpg",
    "picture_medium": "https://cdn-images.dzcdn.net/images/artist/b9eef585fd41e2e8813753f047b60036/250x250-000000-80-0-0.jpg",
    "picture_big": "https://cdn-images.dzcdn.net/images/artist/b9eef585fd41e2e8813753f047b60036/500x500-000000-80-0-0.jpg",
    "picture_xl": "https://cdn-images.dzcdn.net/images/artist/b9eef585fd41e2e8813753f047b60036/1000x1000-000000-80-0-0.jpg",
    "radio": true,
    "tracklist": "https://api.deezer.com/artist/27/top?limit=50",
    "type": "artist"
  },
  "album": {
    "id": 302127,
    "title": "Discovery",
    "link": "https://www.deezer.com/album/302127",
    "cover": "https://api.deezer.com/album/302127/image",
    "cover_small": "https://cdn-images.dzcdn.net/images/cover/5718f7c81c27e0b2417e2a4c45224f8a/56x56-000000-80-0-0.jpg",
    "cover_medium": "https://cdn-images.dzcdn.net/images/cover/5718f7c81c27e0b2417e2a4c45224f8a/250x250-000000-80-0-0.jpg",
    "cover_big": "https://cdn-images.dzcdn.net/images/cover/5718f7c81c27e0b2417e2a4c45224f8a/500x500-000000-80-0-0.jpg",
    "cover_xl": "https://cdn-images.dzcdn.net/images/cover/5718f7c81c27e0b2417e2a4c45224f8a/1000x1000-000000-80-0-0.jpg",
    "md5_image": "5718f7c81c27e0b2417e2a4c45224f8a",
    "release_date": "2001-03-07",
    "tracklist": "https://api.deezer.com/album/302127/tracks",
    "type": "album"
  },
  "type": "track"
)
