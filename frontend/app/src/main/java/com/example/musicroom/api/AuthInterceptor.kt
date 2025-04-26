package com.example.musicroom.api

import android.content.Context
import okhttp3.Interceptor
import okhttp3.Response

class AuthInterceptor(private val context: Context) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        
        val token = context.getSharedPreferences("user_prefs", Context.MODE_PRIVATE)
            .getString("auth_token", null)
        
        return if (token != null) {
            val authenticatedRequest = request.newBuilder()
                .header("Authorization", "Token $token")
                .build()
            chain.proceed(authenticatedRequest)
        } else {
            chain.proceed(request)
        }
    }
}
