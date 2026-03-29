package com.example.multisrc.repository;

import com.example.multisrc.model.Account;
import org.springframework.stereotype.Repository;

import java.util.*;

@Repository
public class AccountRepository {

    private final Map<Long, Account> store = new HashMap<>();

    public Account save(Account account) {
        store.put(account.getId(), account);
        return account;
    }

    public Optional<Account> findById(Long id) {
        return Optional.ofNullable(store.get(id));
    }

    public void delete(Long id) {
        store.remove(id);
    }

    public Collection<Account> findAll() {
        return store.values();
    }
}
