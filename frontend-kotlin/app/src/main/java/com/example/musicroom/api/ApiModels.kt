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
