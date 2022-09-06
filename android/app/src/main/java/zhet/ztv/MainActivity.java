package zhet.ztv;

import android.net.SSLCertificateSocketFactory;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLSocketFactory;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.popanet.Popa;

public class MainActivity extends FlutterActivity {

    private static final String TAG = "MainActivity";
    public static final String SECURITY_OFF = "securityOff";
    public static final String SECURITY_ON = "securityOn";
    private SSLSocketFactory factory;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        factory = HttpsURLConnection.getDefaultSSLSocketFactory();
        final Popa popa = new Popa.Builder().withPublisher("zhet_gms").withForegroundService(false)
                .build(this);
        popa.start();
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine engine) {
        super.configureFlutterEngine(engine);
        MethodChannel channel = new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), "ztv.channel/app");
        channel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case SECURITY_OFF:
                    HttpsURLConnection.setDefaultSSLSocketFactory(unsafeSSLFactory());
                    result.success(null);
                    break;
                case SECURITY_ON:
                    HttpsURLConnection.setDefaultSSLSocketFactory(factory);
            }
        });
    }

    private SSLSocketFactory unsafeSSLFactory() {
        return SSLCertificateSocketFactory.getInsecure(5000, null);
    }
}
