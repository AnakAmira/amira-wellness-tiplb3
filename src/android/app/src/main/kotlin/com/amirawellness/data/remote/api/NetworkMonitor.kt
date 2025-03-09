package com.amirawellness.data.remote.api

import android.content.Context // android version: latest
import android.net.ConnectivityManager // android version: latest
import android.net.Network // android version: latest
import android.net.NetworkCapabilities // android version: latest
import android.net.NetworkRequest // android version: latest
import kotlinx.coroutines.flow.MutableStateFlow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.StateFlow // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.flow.asStateFlow // kotlinx.coroutines version: 1.6.4
import com.amirawellness.core.utils.LogUtils.d as logDebug
import com.amirawellness.core.utils.LogUtils.e as logError
import javax.inject.Inject // javax.inject version: 1
import javax.inject.Singleton // javax.inject version: 1

private const val TAG = "NetworkMonitor"

/**
 * Monitors network connectivity status and provides real-time updates
 * about network availability, allowing the application to adapt its behavior
 * for offline scenarios and implement appropriate synchronization strategies
 * when connectivity is restored.
 */
@Singleton
class NetworkMonitor @Inject constructor(context: Context) {

    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val networkStatusFlow = MutableStateFlow(isNetworkAvailable())
    
    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            updateNetworkStatus()
        }

        override fun onLost(network: Network) {
            updateNetworkStatus()
        }

        override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
            updateNetworkStatus()
        }
    }

    /**
     * Checks if network connectivity is currently available
     *
     * @return True if network is available, false otherwise
     */
    fun isNetworkAvailable(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }

    /**
     * Gets a StateFlow that emits network availability status
     *
     * @return Flow of network availability status (true when available)
     */
    fun getNetworkStatusFlow(): StateFlow<Boolean> = networkStatusFlow.asStateFlow()

    /**
     * Starts monitoring network connectivity changes
     */
    fun startMonitoring() {
        try {
            val request = NetworkRequest.Builder()
                .addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .addTransportType(NetworkCapabilities.TRANSPORT_ETHERNET)
                .build()
            connectivityManager.registerNetworkCallback(request, networkCallback)
            logDebug(TAG, "Network monitoring started")
        } catch (e: Exception) {
            logError(TAG, "Error starting network monitoring", e)
        }
    }

    /**
     * Stops monitoring network connectivity changes
     */
    fun stopMonitoring() {
        try {
            connectivityManager.unregisterNetworkCallback(networkCallback)
            logDebug(TAG, "Network monitoring stopped")
        } catch (e: Exception) {
            logError(TAG, "Error stopping network monitoring", e)
        }
    }

    /**
     * Updates the network status flow with current connectivity state
     */
    private fun updateNetworkStatus() {
        val isAvailable = isNetworkAvailable()
        networkStatusFlow.value = isAvailable
        logDebug(TAG, "Network status changed: available = $isAvailable")
    }
}

/**
 * Singleton provider for NetworkMonitor instance
 */
object NetworkMonitorProvider {
    private var instance: NetworkMonitor? = null

    /**
     * Gets or creates the singleton NetworkMonitor instance
     *
     * @param context Application context
     * @return The singleton NetworkMonitor instance
     */
    fun getInstance(context: Context): NetworkMonitor {
        if (instance == null) {
            instance = NetworkMonitor(context.applicationContext)
        }
        return instance!!
    }

    /**
     * Resets the singleton instance (for testing purposes)
     */
    fun resetInstance() {
        instance = null
    }
}