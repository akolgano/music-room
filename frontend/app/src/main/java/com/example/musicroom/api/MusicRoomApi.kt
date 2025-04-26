package com.example.musicroom.api

import retrofit2.Response
import retrofit2.http.*

interface MusicRoomApi {
    @GET("deezer/track/<str:track_id>/")
    suspend fun deezerTrack(): Response<DeezerTrackResponse>

    @GET("deezer/search/")
    suspend fun deezerSearch(): Response<DeezerSearchResponse>

    @POST("playlists/save_playlist/")
    suspend fun saveSharedPlaylist(@Body request: SavePlaylistRequest): Response<>    

    @GET("playlists/saved_playlists/")
    

    @GET("playlists/public_playlists/")
    

    @POST("playlists/to_playlist/<int:playlist_id>/add_track/<int:track_id>/")



    @POST("users/signup/")
    suspend fun registerUser(@Body request: UserRegistrationRequest): Response<UserAuthResponse>
    
    @POST("users/login/")
    suspend fun loginUser(@Body request: UserLoginRequest): Response<UserAuthResponse>
    
    @POST("users/logout/")
    suspend fun logoutUser(@Body request: LogoutRequest): Response<String>
}
