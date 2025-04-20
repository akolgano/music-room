package com.example.musicroom

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import kotlinx.coroutines.launch
import kotlinx.coroutines.MainScope
import org.json.JSONObject
import java.net.URL

class UserAuthManager(private val context: Context) {
    private val sharedPreferences = context.getSharedPreferences("user_prefs", Context.MODE_PRIVATE)
    private val _authState = MutableStateFlow<AuthState>(AuthState.NotAuthenticated)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()
    
    private val _userProfile = MutableStateFlow<UserProfile?>(null)
    val userProfile: StateFlow<UserProfile?> = _userProfile.asStateFlow()
    
    init {
        val isLoggedIn = sharedPreferences.getBoolean("is_authenticated", false)
        if (isLoggedIn) {
            loadUserProfile()
            _authState.value = AuthState.Authenticated
        }
    }
    
    private fun loadUserProfile() {
        val userId = sharedPreferences.getString("user_id", "") ?: ""
        val email = sharedPreferences.getString("email", "") ?: ""
        val displayName = sharedPreferences.getString("display_name", "") ?: ""
        val profilePicUrl = sharedPreferences.getString("profile_pic_url", "") ?: ""
        
        val musicPrefs = sharedPreferences.getString("music_preferences", "[]") ?: "[]"
        
        _userProfile.value = UserProfile(
            id = userId,
            email = email,
            displayName = displayName,
            profilePicUrl = profilePicUrl,
musicPreferences = parseMusicPrefs(musicPrefs)
        )
    }
    
    private fun parseMusicPrefs(prefsJson: String): List<String> {
        return try {
            val jsonArray = org.json.JSONArray(prefsJson)
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
                
                Thread.sleep(1000)
                
                val userId = "user_${System.currentTimeMillis()}"
                sharedPreferences.edit()
                    .putString("user_id", userId)
                    .putString("email", email)
                    .putString("display_name", email.substringBefore("@"))
                    .putBoolean("is_authenticated", true)
                    .apply()
                
                _authState.value = AuthState.Authenticated
                _userProfile.value = UserProfile(
                    id = userId,
                    email = email,
                    displayName = email.substringBefore("@"),
                    profilePicUrl = "",
                    musicPreferences = emptyList()
                )
                
                Result.success(Unit)
            } catch (e: Exception) {
                Log.e("UserAuthManager", "Error registering user", e)
                Result.failure(e)
            }
        }
    }
    
    suspend fun loginWithEmail(email: String, password: String): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                Thread.sleep(1000)
                
                val storedEmail = sharedPreferences.getString("email", null)
                if (storedEmail != email) {
                    return@withContext Result.failure(IllegalArgumentException("Email not found"))
                }
                
                sharedPreferences.edit()
                    .putBoolean("is_authenticated", true)
                    .apply()
                
                loadUserProfile()
                
                _authState.value = AuthState.Authenticated
                
                Result.success(Unit)
            } catch (e: Exception) {
                Log.e("UserAuthManager", "Error logging in", e)
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
                    .putString("music_preferences", JSONObject(updatedProfile.musicPreferences.associateWith { true }).toString())
                    .apply()
                
                _userProfile.value = updatedProfile
                
                Result.success(Unit)
            } catch (e: Exception) {
                Log.e("UserAuthManager", "Error updating profile", e)
                Result.failure(e)
            }
        }
    }
    
    fun logout() {
        sharedPreferences.edit()
            .putBoolean("is_authenticated", false)
            .apply()
        
        _authState.value = AuthState.NotAuthenticated
        _userProfile.value = null
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

@Composable
fun LoginScreen(
    authManager: UserAuthManager,
    onLoginSuccess: () -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val windowSize = rememberWindowSizeClass()
    
    LaunchedEffect(authManager.authState) {
        authManager.authState.collect { state ->
            if (state is AuthState.Authenticated) {
                onLoginSuccess()
            }
        }
    }
    
    if (windowSize.isLandscape) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "Music Room",
                    style = adaptiveTextStyle(windowSize, MaterialTheme.typography.headlineLarge)
                )
                
                Text(
                    text = "Your collaborative music experience",
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }
            
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .verticalScroll(rememberScrollState())
                    .padding(start = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Email") },
                    modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email)
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Password") },
                    modifier = Modifier.fillMaxWidth(),
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password)
                )
                
                if (errorMessage != null) {
                    Text(
                        text = errorMessage ?: "",
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                }
                
                Button(
                    onClick = {
                        isLoading = true
                        errorMessage = null
                        
                        MainScope().launch {
                            val result = authManager.loginWithEmail(email, password)
                            isLoading = false
                            
                            result.onFailure { error ->
                                errorMessage = error.message ?: "Login failed"
                            }
                        }
                    },
                    modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                    enabled = !isLoading && email.isNotEmpty() && password.isNotEmpty()
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    } else {
                        Text("Login")
                    }
                }
                
                TextButton(onClick = { authManager.resetPassword(email) }) {
                    Text("Forgot Password?")
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Button(
                        onClick = { authManager.loginWithGoogle() },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.secondary
                        )
                    ) {
                        Text("Google")
                    }
                    
                    Button(
                        onClick = { authManager.loginWithFacebook() },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.tertiary
                        )
                    ) {
                        Text("Facebook")
                    }
                }
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(top = 8.dp)
                ) {
                    Text("Don't have an account?")
                    Spacer(modifier = Modifier.width(4.dp))
                    TextButton(onClick = {
                        MainScope().launch {
                            if (email.isNotEmpty() && password.isNotEmpty()) {
                                authManager.registerUser(email, password)
                            } else {
                                errorMessage = "Please enter email and password to register"
                            }
                        }
                    }) {
                        Text("Sign Up")
                    }
                }
            }
        }
    } else {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(rememberResponsivePadding(windowSize))
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "Music Room",
                style = adaptiveTextStyle(windowSize, MaterialTheme.typography.headlineMedium)
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email") },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email)
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                modifier = Modifier.fillMaxWidth(),
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password)
            )
            
            if (errorMessage != null) {
                Text(
                    text = errorMessage ?: "",
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }
            
            Button(
                onClick = {
                    isLoading = true
                    errorMessage = null
                    
                    MainScope().launch {
                        val result = authManager.loginWithEmail(email, password)
                        isLoading = false
                        
                        result.onFailure { error ->
                            errorMessage = error.message ?: "Login failed"
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = !isLoading && email.isNotEmpty() && password.isNotEmpty()
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Text("Login")
                }
            }
            
            TextButton(onClick = { authManager.resetPassword(email) }) {
                Text("Forgot Password?")
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                Button(
                    onClick = { authManager.loginWithGoogle() },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.secondary
                    )
                ) {
                    Text("Google")
                }
                
                Button(
                    onClick = { authManager.loginWithFacebook() },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.tertiary
                    )
                ) {
                    Text("Facebook")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Don't have an account?")
                Spacer(modifier = Modifier.width(4.dp))
                TextButton(onClick = {
                    MainScope().launch {
                        if (email.isNotEmpty() && password.isNotEmpty()) {
                            authManager.registerUser(email, password)
                        } else {
                            errorMessage = "Please enter email and password to register"
                        }
                    }
                }) {
                    Text("Sign Up")
                }
            }
        }
    }
}

@Composable
fun ProfileScreen(
    authManager: UserAuthManager,
    onLogout: () -> Unit
) {
    val userProfile by authManager.userProfile.collectAsState()
    val windowSize = rememberWindowSizeClass()
    
    var displayName by remember { mutableStateOf(userProfile?.displayName ?: "") }
    var musicPreference by remember { mutableStateOf("") }
    var musicPreferences by remember { mutableStateOf(userProfile?.musicPreferences ?: emptyList()) }
    
    if (windowSize.isLandscape) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .verticalScroll(rememberScrollState())
                    .padding(end = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Your Profile",
                    style = adaptiveTextStyle(windowSize, MaterialTheme.typography.headlineMedium)
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                OutlinedTextField(
                    value = displayName,
                    onValueChange = { displayName = it },
                    label = { Text("Display Name") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "Email: ${userProfile?.email ?: ""}",
                    modifier = Modifier.fillMaxWidth()
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "Link Accounts",
                    style = MaterialTheme.typography.titleMedium
                )
                
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Button(
                        onClick = { authManager.linkSocialAccount(SocialProvider.GOOGLE) },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.secondary
                        )
                    ) {
                        Text("Google")
                    }
                    
                    Button(
                        onClick = { authManager.linkSocialAccount(SocialProvider.FACEBOOK) },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.tertiary
                        )
                    ) {
                        Text("Facebook")
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Button(
                    onClick = {
                        MainScope().launch {
                            authManager.updateProfile(
                                displayName = displayName
                            )
                        }
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Save Profile")
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Button(
                    onClick = {
                        authManager.logout()
                        onLogout()
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Logout")
                }
            }
            
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .verticalScroll(rememberScrollState())
                    .padding(start = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Music Preferences",
                    style = adaptiveTextStyle(windowSize, MaterialTheme.typography.titleMedium),
                    modifier = Modifier.padding(bottom = 16.dp)
                )
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = musicPreference,
                        onValueChange = { musicPreference = it },
                        label = { Text("Add Genre/Artist") },
                        modifier = Modifier.weight(1f)
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Button(onClick = {
                        if (musicPreference.isNotEmpty()) {
                            musicPreferences = musicPreferences + musicPreference
                            musicPreference = ""
                            
                            MainScope().launch {
                                authManager.updateProfile(
                                    musicPreferences = musicPreferences
                                )
                            }
                        }
                    }) {
                        Text("Add")
                    }
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                musicPreferences.forEach { pref ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(pref)
                            
                            Button(
                                onClick = {
                                    musicPreferences = musicPreferences - pref
                                    
                                    MainScope().launch {
                                        authManager.updateProfile(
                                            musicPreferences = musicPreferences
                                        )
                                    }
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.error
                                )
                            ) {
                                Text("Remove")
                            }
                        }
                    }
                }
            }
        }
    } else {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(rememberResponsivePadding(windowSize))
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Your Profile",
                style = adaptiveTextStyle(windowSize, MaterialTheme.typography.headlineMedium)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            OutlinedTextField(
                value = displayName,
                onValueChange = { displayName = it },
                label = { Text("Display Name") },
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Email: ${userProfile?.email ?: ""}",
                modifier = Modifier.fillMaxWidth()
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "Music Preferences",
                style = MaterialTheme.typography.titleMedium
            )
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = musicPreference,
                    onValueChange = { musicPreference = it },
                    label = { Text("Add Genre/Artist") },
                    modifier = Modifier.weight(1f)
                )
                
                Spacer(modifier = Modifier.width(8.dp))
                
                Button(onClick = {
                    if (musicPreference.isNotEmpty()) {
                        musicPreferences = musicPreferences + musicPreference
                        musicPreference = ""
                        
                        MainScope().launch {
                            authManager.updateProfile(
                                musicPreferences = musicPreferences
                            )
                        }
                    }
                }) {
                    Text("Add")
                }
            }
            
            musicPreferences.forEach { pref ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(pref)
                        
                        Button(
                            onClick = {
                                musicPreferences = musicPreferences - pref
                                
                                MainScope().launch {
                                    authManager.updateProfile(
                                        musicPreferences = musicPreferences
                                    )
                                }
                            },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Text("Remove")
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                Button(
                    onClick = { authManager.linkSocialAccount(SocialProvider.GOOGLE) },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.secondary
                    )
                ) {
                    Text("Link Google")
                }
                
                Button(
                    onClick = { authManager.linkSocialAccount(SocialProvider.FACEBOOK) },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.tertiary
                    )
                ) {
                    Text("Link Facebook")
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Button(
                onClick = {
                    MainScope().launch {
                        authManager.updateProfile(
                            displayName = displayName,
                            musicPreferences = musicPreferences
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Save Changes")
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Button(
                onClick = {
                    authManager.logout()
                    onLogout()
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Logout")
            }
        }
    }
}
