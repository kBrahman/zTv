package zhet.ztv;

import android.annotation.SuppressLint;
import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.net.SSLCertificateSocketFactory;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLSocketFactory;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String TAG = "MainActivity";
    public static final String SECURITY_OFF = "securityOff";
    public static final String SECURITY_ON = "securityOn";
    public static final String CHECK_CONN = "checkConn";
    private SSLSocketFactory factory;
    private MethodChannel channel;
//    private final ConnectivityManager.NetworkCallback networkCallback =

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        factory = HttpsURLConnection.getDefaultSSLSocketFactory();
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine engine) {
        super.configureFlutterEngine(engine);
        channel = new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), "ztv.channel/app");
        channel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case SECURITY_OFF:
                    HttpsURLConnection.setDefaultSSLSocketFactory(unsafeSSLFactory());
                    result.success(null);
                    break;
                case SECURITY_ON:
                    HttpsURLConnection.setDefaultSSLSocketFactory(factory);
                    break;
                case CHECK_CONN:
                    checkConn(this, result);

            }
        });
    }

    private void checkConn(Context context, MethodChannel.Result result) {
        NetworkRequest networkRequest = new NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
                .build();
        ConnectivityManager cm = ContextCompat.getSystemService(context, ConnectivityManager.class);
        if (cm == null)
            result.success(false);
        else {
            result.success(true);
            cm.registerNetworkCallback(networkRequest, new ConnectivityManager.NetworkCallback() {
                @Override
                public void onAvailable(@NonNull Network network) {
                    super.onAvailable(network);
                    runOnUiThread(() -> channel.invokeMethod("onAvailable", null));
                    Log.i(TAG, "onAvailable");
                }

                @Override
                public void onLost(@NonNull Network network) {
                    super.onLost(network);
                    runOnUiThread(() -> channel.invokeMethod("onLost", null));
                    Log.i(TAG, "onLost");
                }

                @Override
                public void onCapabilitiesChanged(@NonNull Network network, @NonNull NetworkCapabilities networkCapabilities) {
                    super.onCapabilitiesChanged(network, networkCapabilities);
                    final boolean unmetered = networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED);
                }
            });
        }
    }

    @SuppressLint("SSLCertificateSocketFactoryGetInsecure")
    private SSLSocketFactory unsafeSSLFactory() {
        return SSLCertificateSocketFactory.getInsecure(5000, null);
    }
}
