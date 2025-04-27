package com.example.musicroom

import com.example.musicroom.api.*
import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import org.json.JSONObject
import org.json.JSONArray

class UserAuthManager(private val context: Context) {
    private val TAG = "UserAuthManager"
    private val sharedPreferences = context.getSharedPreferences("user_prefs", Context.MODE_PRIVATE)
    private val _authState = MutableStateFlow<AuthState>(AuthState.NotAuthenticated)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()
    
    private val _userProfile = MutableStateFlow<UserProfile?>(null)
    val userProfile: StateFlow<UserProfile?> = _userProfile.asStateFlow()
    
    private val apiClient = RetrofitClient.api
    
    init {
        val token = sharedPreferences.getString("auth_token", null)
        if (token != null) {
            loadUserProfile()
            _authState.value = AuthState.Authenticated
        }
    }
    
    private fun loadUserProfile() {
        val userId = sharedPreferences.getString("user_id", "") ?: ""
        val username = sharedPreferences.getString("username", "") ?: ""
        val email = sharedPreferences.getString("email", "") ?: ""
        val profilePicUrl = sharedPreferences.getString("profile_pic_url", "") ?: ""
        
        val musicPrefs = sharedPreferences.getString("music_preferences", "[]") ?: "[]"
        
        _userProfile.value = UserProfile(
            id = userId,
            email = email,
            displayName = username,
            profilePicUrl = profilePicUrl,
            musicPreferences = parseMusicPrefs(musicPrefs)
        )
    }
    
    private fun parseMusicPrefs(prefsJson: String): List<String> {
        return try {
            val jsonArray = JSONArray(prefsJson)
            List(jsonArray.length()) { i -> jsonArray.getString(i) }
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    suspend fun registerUser(email: String, password: String): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
                    return@withContext Result.failure(IllegalArgumentException("Invalid email format"))
                }
                
                if (password.length < 8) {
                    return@withContext Result.failure(IllegalArgumentException("Password must be at least 8 characters"))
                }
                
                val username = email.substringBefore("@").replace(".", "_").lowercase()
                val request = UserRegistrationRequest(
                    username = username,
                    email = email,
                    password = password
                )
                
                val response = apiClient.registerUser(request)
                
                if (response.isSuccessful) {
                    val authResponse = response.body()
                    if (authResponse != null) {
                        sharedPreferences.edit()
                            .putString("auth_token", authResponse.token)
                            .putString("user_id", authResponse.user.id.toString())
                            .putString("username", authResponse.user.username)
                            .putString("email", authResponse.user.email)
                            .putBoolean("is_authenticated", true)
                            .apply()
                        
                        _authState.value = AuthState.Authenticated
                        _userProfile.value = UserProfile(
                            id = authResponse.user.id.toString(),
                            email = authResponse.user.email,
                            displayName = authResponse.user.username,
                            profilePicUrl = "",
                            musicPreferences = emptyList()
                        )
                        
                        Result.success(Unit)
                    } else {
                        Result.failure(Exception("Empty response body"))
                    }
                } else {
                    val errorBody = response.errorBody()?.string() ?: "Unknown error"
                    Log.e(TAG, "Registration error: $errorBody")
                    Result.failure(Exception(errorBody))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error registering user", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun loginWithEmail(email: String, password: String): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                val username = email.substringBefore("@")
                
                val request = UserLoginRequest(
                    username = username,
                    password = password
                )
                
                val response = apiClient.loginUser(request)
                
                if (response.isSuccessful) {
                    val authResponse = response.body()
                    if (authResponse != null) {
                        sharedPreferences.edit()
                            .putString("auth_token", authResponse.token)
                            .putString("user_id", authResponse.user.id.toString())
                            .putString("username", authResponse.user.username)
                            .putString("email", authResponse.user.email)
                            .putBoolean("is_authenticated", true)
                            .apply()
                        
                        _authState.value = AuthState.Authenticated
                        _userProfile.value = UserProfile(
                            id = authResponse.user.id.toString(),
                            email = authResponse.user.email,
                            displayName = authResponse.user.username,
                            profilePicUrl = "",
                            musicPreferences = emptyList()
                        )
                        
                        Result.success(Unit)
                    } else {
                        Result.failure(Exception("Empty response body"))
                    }
                } else {
                    val errorBody = response.errorBody()?.string() ?: "Unknown error"
                    Log.e(TAG, "Login error: $errorBody")
                    Result.failure(Exception(errorBody))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error logging in", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun logout(): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                val userProfile = _userProfile.value ?: return@withContext Result.failure(
                    IllegalStateException("User not logged in")
                )
                
                val request = LogoutRequest(
                    username = userProfile.displayName
                )
                
                val response = apiClient.logoutUser(request)
                
                if (response.isSuccessful) {
                    sharedPreferences.edit()
                        .remove("auth_token")
                        .putBoolean("is_authenticated", false)
                        .apply()
                    
                    _authState.value = AuthState.NotAuthenticated
                    _userProfile.value = null
                    
                    Result.success(Unit)
                } else {
                    val errorBody = response.errorBody()?.string() ?: "Unknown error"
                    Log.e(TAG, "Logout error: $errorBody")
                    Result.failure(Exception(errorBody))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error logging out", e)
                Result.failure(e)
            }
        }
    }
    
    fun loginWithGoogle() {
        val userId = "google_user_${System.currentTimeMillis()}"
        val email = "google_user@example.com"
        val displayName = "Google User"
        val profilePicUrl = ""
        
        sharedPreferences.edit()
            .putString("user_id", userId)
            .putString("email", email)
            .putString("display_name", displayName)
            .putString("profile_pic_url", profilePicUrl)
            .putBoolean("is_authenticated", true)
            .apply()
        
        _userProfile.value = UserProfile(
            id = userId,
            email = email,
            displayName = displayName,
            profilePicUrl = profilePicUrl,
            musicPreferences = emptyList()
        )
        
        _authState.value = AuthState.Authenticated
    }
    
    fun loginWithFacebook() {
        val userId = "facebook_user_${System.currentTimeMillis()}"
        val email = "facebook_user@example.com"
        val displayName = "Facebook User"
        val profilePicUrl = ""
        
        sharedPreferences.edit()
            .putString("user_id", userId)
            .putString("email", email)
            .putString("display_name", displayName)
            .putString("profile_pic_url", profilePicUrl)
            .putBoolean("is_authenticated", true)
            .apply()
        
        _userProfile.value = UserProfile(
            id = userId,
            email = email,
            displayName = displayName,
            profilePicUrl = profilePicUrl,
            musicPreferences = emptyList()
        )
        
        _authState.value = AuthState.Authenticated
    }
    
    suspend fun updateProfile(
        displayName: String? = null,
        profilePicUrl: String? = null,
        publicInfo: Map<String, String>? = null,
        friendsOnlyInfo: Map<String, String>? = null,
        privateInfo: Map<String, String>? = null,
        musicPreferences: List<String>? = null
    ): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                val currentProfile = _userProfile.value ?: return@withContext Result.failure(
                    IllegalStateException("User not logged in")
                )
                
                val updatedProfile = currentProfile.copy(
                    displayName = displayName ?: currentProfile.displayName,
                    profilePicUrl = profilePicUrl ?: currentProfile.profilePicUrl,
                    publicInfo = publicInfo ?: currentProfile.publicInfo,
                    friendsOnlyInfo = friendsOnlyInfo ?: currentProfile.friendsOnlyInfo,
                    privateInfo = privateInfo ?: currentProfile.privateInfo,
                    musicPreferences = musicPreferences ?: currentProfile.musicPreferences
                )
                
                sharedPreferences.edit()
                    .putString("display_name", updatedProfile.displayName)
                    .putString("profile_pic_url", updatedProfile.profilePicUrl)
                    .putString("public_info", JSONObject(updatedProfile.publicInfo).toString())
                    .putString("friends_only_info", JSONObject(updatedProfile.friendsOnlyInfo).toString())
                    .putString("private_info", JSONObject(updatedProfile.privateInfo).toString())
                    .putString("music_preferences", JSONArray(updatedProfile.musicPreferences).toString())
                    .apply()
                
                _userProfile.value = updatedProfile
                
                Result.success(Unit)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating profile", e)
                Result.failure(e)
            }
        }
    }
    
    fun resetPassword(email: String): Result<Unit> {
        return Result.success(Unit)
    }
    
    fun linkSocialAccount(provider: SocialProvider): Boolean {
        return true
    }
}

sealed class AuthState {
    object NotAuthenticated : AuthState()
    object Authenticated : AuthState()
}

enum class SocialProvider {
    GOOGLE, FACEBOOK
}

data class UserProfile(
    val id: String,
    val email: String,
    val displayName: String,
    val profilePicUrl: String = "",
    val publicInfo: Map<String, String> = emptyMap(),
    val friendsOnlyInfo: Map<String, String> = emptyMap(),
    val privateInfo: Map<String, String> = emptyMap(),
    val musicPreferences: List<String> = emptyList()
)
