package com.example;

import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomeController {

	private final EmbeddingModel embeddingModel;

	public HomeController(EmbeddingModel embeddingModel) {
		this.embeddingModel = embeddingModel;
	}

	@GetMapping("/")
	public int home() {
		return embeddingModel.embed("Azure Developer CLI").length;
	}
}
