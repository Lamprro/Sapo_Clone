package com.example.Sapo_Clone.Config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
public class RedisConfig {

    @Bean
    public RedisTemplate<String, String> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, String> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);
        
        StringRedisSerializer stringSerializer = new StringRedisSerializer();
        template.setKeySerializer(stringSerializer);
        template.setValueSerializer(stringSerializer);
        template.setHashKeySerializer(stringSerializer);
        template.setHashValueSerializer(stringSerializer);
        
        template.afterPropertiesSet();
        return template;
    }


    @org.springframework.beans.factory.annotation.Autowired
    private RedisConnectionFactory redisConnectionFactory;

    // Tự động xóa cache cũ trên Redis khi ứng dụng khởi động
    @jakarta.annotation.PostConstruct
    public void clearCache() {
        try {
            System.out.println("Clearing old Redis cache data to avoid SerializationException...");
            redisConnectionFactory.getConnection().serverCommands().flushDb();
            System.out.println("Redis cache cleared successfully.");
        } catch (Exception e) {
            System.out.println("Failed to clear Redis cache: " + e.getMessage());
        }
    }
}
