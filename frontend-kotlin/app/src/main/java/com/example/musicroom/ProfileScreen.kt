package com.example.musicroom

import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

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
                        MainScope().launch {
                            val result = authManager.logout()
                            result.onSuccess {
                                onLogout()
                            }.onFailure { error ->
                                Log.e("ProfileScreen", "Logout failed", error)
                            }
                        }
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
                    MainScope().launch {
                        val result = authManager.logout()
                        result.onSuccess {
                            onLogout()
                        }.onFailure { error ->
                            Log.e("ProfileScreen", "Logout failed", error)
                        }
                    }
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
