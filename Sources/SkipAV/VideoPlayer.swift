// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
#if canImport(AVKit)
@_exported import AVKit
#elseif SKIP
import SwiftUI
import androidx.compose.runtime.Composable
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.ui.PlayerView
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.compose.PlayerSurface
import androidx.media3.ui.compose.SURFACE_TYPE_SURFACE_VIEW
import androidx.media3.ui.compose.modifiers.resizeWithContentScale
import androidx.media3.ui.compose.state.rememberPresentationState
import androidx.compose.ui.platform.LocalContext
import androidx.activity.ComponentActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

public struct VideoPlayer: View {
    
    let player: AVPlayer
    
    var isFullscreen: Binding<Bool>?

    public init(player: AVPlayer) {
        self.player = player
        self.isFullscreen = nil
    }
    
    /// Android-only API to handle fullscreen button
    public init(player: AVPlayer, isFullscreen: Binding<Bool>) {
        self.player = player
        self.isFullscreen = isFullscreen
    }

    // SKIP @nobridge
    @Composable public override func ComposeContent(context: ComposeContext) {
        // Capture the context in the composable scope
        let ctx = LocalContext.current
        
        ComposeContainer(modifier: context.modifier, fillWidth: true, fillHeight: false) { modifier in
            // we could use the newer Compose PlayerSurface, but unlike the older PlayerView, it doesn't include built-in playback controls, so we would need to create our own
            /*
            player.prepare(LocalContext.current)
            let presentationState = rememberPresentationState(player.mediaPlayer!)
            PlayerSurface(player: player.mediaPlayer!, surfaceType: SURFACE_TYPE_SURFACE_VIEW, modifier: modifier.resizeWithContentScale(ContentScale.Fit, presentationState.videoSizeDp))
             */

            AndroidView(factory: { factoryCtx in
                let playerView = PlayerView(factoryCtx)
                player.prepare(factoryCtx)
                playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                playerView.controllerAutoShow = false // hide controls initially, like on iOS
                playerView.player = player.mediaPlayer
                // Enable fullscreen button and handle fullscreen transitions
                if let isFullscreenBinding = self.isFullscreen {
                    playerView.setControllerOnFullScreenModeChangedListener { isFullScreen in
                        isFullscreenBinding.wrappedValue = isFullScreen
                        if (isFullScreen) {
                            if let activity = ctx as? ComponentActivity {
                                if let window = activity.window {
                                    // Hide system UI using modern WindowInsetsController
                                    WindowCompat.setDecorFitsSystemWindows(window, false)
                                    let insetsController = WindowCompat.getInsetsController(window, window.decorView)
                                    // Hide status bars and navigation bars
                                    insetsController?.hide(WindowInsetsCompat.`Type`.systemBars())
                                    insetsController?.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                                }
                                
                                // Change player to fill screen
                                playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL
                            }
                        } else {
                            if let activity = ctx as? ComponentActivity {
                                if let window = activity.window {
                                    // Restore system UI
                                    let insetsController = WindowCompat.getInsetsController(window, window.decorView)
                                    insetsController?.show(WindowInsetsCompat.`Type`.systemBars())
                                    WindowCompat.setDecorFitsSystemWindows(window, true)
                                }
                                
                                // Restore original resize mode
                                playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                            }
                        }
                    }
                }
                return playerView
            }, modifier: modifier, update: { playerView in
            })
        }
    }
}
#endif
#endif
