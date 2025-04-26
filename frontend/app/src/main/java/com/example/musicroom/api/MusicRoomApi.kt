package com.example.musicroom.api

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface MusicRoomApi {
    @POST("users/signup/")
    suspend fun registerUser(@Body request: UserRegistrationRequest): Response<UserAuthResponse>
    
    @POST("users/login/")
    suspend fun loginUser(@Body request: UserLoginRequest): Response<UserAuthResponse>
    
    @POST("users/logout/")
    suspend fun logoutUser(@Body request: LogoutRequest): Response<String>
}
