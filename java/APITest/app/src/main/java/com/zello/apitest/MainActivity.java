package com.zello.apitest;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;

public class MainActivity extends AppCompatActivity {

	private APITest apiTest;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		setContentView(R.layout.activity_main);

		// Input your host url or IP address, your API key, and the administrative username/password combination.
		apiTest = new APITest("https://testing.zellowork.com/", "QSAEV6ZUGJ4BEJJNW49CUL6ALM70XGN7", "admin", "secret");
	}

}
