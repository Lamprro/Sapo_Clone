package com.example.Sapo_Clone.Config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

@Configuration
public class AsyncConfig {

    @Bean(name = "imageUploadExecutor")
    public Executor imageUploadExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5); // Minimum threads
        executor.setMaxPoolSize(10); // Maximum threads
        executor.setQueueCapacity(25); // Queue size before creating new threads up to maxPoolSize
        executor.setThreadNamePrefix("ImageUpload-");
        executor.initialize();
        return executor;
    }

    @Bean(name = "reportExportExecutor")
    public Executor reportExportExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(5);
        executor.setQueueCapacity(50);
        executor.setThreadNamePrefix("ReportExport-");
        executor.initialize();
        return executor;
    }
}
