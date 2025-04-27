package com.example.musicroom

import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

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
                                isLoading = true
                                errorMessage = null
                                
                                val result = authManager.registerUser(email, password)
                                isLoading = false
                                
                                result.onFailure { error ->
                                    errorMessage = error.message ?: "Registration failed"
                                }
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
                            isLoading = true
                            errorMessage = null
                            
                            val result = authManager.registerUser(email, password)
                            isLoading = false
                            
                            result.onFailure { error ->
                                errorMessage = error.message ?: "Registration failed"
                            }
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
