package com.example.Sapo_Clone.Common;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public abstract class AppEvent<T> extends ApplicationEvent {
    private final T data;

    public AppEvent(Object source, T data) {
        super(source);
        this.data = data;
    }
}
