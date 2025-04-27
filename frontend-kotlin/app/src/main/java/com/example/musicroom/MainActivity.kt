package com.example.musicroom

import com.example.musicroom.api.RetrofitClient
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import android.widget.Toast
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

class MainActivity : ComponentActivity() {
    private lateinit var userAuthManager: UserAuthManager
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        RetrofitClient.init(this)
        userAuthManager = UserAuthManager(this)
        
        setContent {
            MaterialTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val authState by userAuthManager.authState.collectAsState()
                    
                    when (authState) {
                        is AuthState.NotAuthenticated -> {
                            LoginScreen(userAuthManager) {
                            }
                        }
                        is AuthState.Authenticated -> {
                            AppNavigator(userAuthManager)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun AppNavigator(userAuthManager: UserAuthManager) {
    val navController = rememberNavController()
    
    NavHost(navController = navController, startDestination = "main") {
        composable("main") {
            MainScreen(navController)
        }
        
        composable("profile") {
            ProfileScreen(userAuthManager) {
                navController.popBackStack()
            }
        }
    }
}

@Composable
fun MainScreen(navController: NavHostController) {
    val windowSize = rememberWindowSizeClass()
    val context = LocalContext.current
    
    Box(modifier = Modifier.fillMaxSize()) {
        if (windowSize.isLandscape) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "Music Room",
                    style = adaptiveTextStyle(windowSize, MaterialTheme.typography.headlineMedium),
                    modifier = Modifier.padding(bottom = 24.dp)
                )
               
                // Music Control Delegation not implemented as pdf only requires 2/3
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Button(
                        onClick = { Toast.makeText(context, "Music Track Vote feature coming soon", Toast.LENGTH_SHORT).show() },
                        modifier = Modifier.weight(1f).padding(horizontal = 8.dp)
                    ) {
                        Text("Track Vote")
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Button(
                        onClick = { Toast.makeText(context, "Music Playlist Editor feature coming soon", Toast.LENGTH_SHORT).show() },
                        modifier = Modifier.weight(1f).padding(horizontal = 8.dp)
                    ) {
                        Text("Playlist Editor")
                    }
                    
                    Button(
                        onClick = { navController.navigate("profile") },
                        modifier = Modifier.weight(1f).padding(horizontal = 8.dp)
                    ) {
                        Text("Profile")
                    }
                }
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "Music Room",
                    style = adaptiveTextStyle(windowSize, MaterialTheme.typography.headlineMedium),
                    modifier = Modifier.padding(bottom = 24.dp)
                )
                
                Button(
                    onClick = { Toast.makeText(context, "Music Track Vote feature coming soon", Toast.LENGTH_SHORT).show() },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Track Vote")
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Button(
                    onClick = { Toast.makeText(context, "Music Playlist Editor feature coming soon", Toast.LENGTH_SHORT).show() },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Playlist Editor")
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Button(
                    onClick = { navController.navigate("profile") },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Profile")
                }
            }
        }
    }
}
