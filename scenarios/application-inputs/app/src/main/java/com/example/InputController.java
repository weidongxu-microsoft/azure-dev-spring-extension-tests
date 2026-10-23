// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

package com.example;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class InputController {
	private final String greeting;
	private final String secret;

	public InputController(
			@Value("${APP_GREETING}") String greeting,
			@Value("${JWT_SECRET}") String secret) {
		this.greeting = greeting;
		this.secret = secret;
	}

	@GetMapping("/inputs")
	public Map<String, Object> inputs() {
		return Map.of(
				"greeting", greeting,
				"secretConfigured", !secret.isBlank());
	}
}
