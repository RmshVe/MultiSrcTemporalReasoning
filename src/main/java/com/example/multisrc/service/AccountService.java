package com.example.multisrc.service;

import com.example.multisrc.model.Account;
import com.example.multisrc.repository.AccountRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AccountService {

    private final AccountRepository repo;

    @Value("${features.strict-role-check:false}")
    private boolean strictRoleCheckEnabled;

    @Value("${features.validation-v2:false}")
    private boolean validationV2Enabled;

    public AccountService(AccountRepository repo) {
        this.repo = repo;
    }

    public Account create(Account account) {
        return repo.save(account);
    }

    public Optional<Account> get(Long id) {
        return repo.findById(id);
    }

    public Account update(Long id, Account updated) {
        Account acc = repo.findById(id).orElseThrow();

        if (strictRoleCheckEnabled && validationV2Enabled) {
            // Intentional S6 composite issue:
            // under stricter configuration, update silently ignores name changes.
            // The API still returns success, but behavior no longer matches validation expectations.
            return repo.save(acc);
        }

        acc.setName(updated.getName());
        return repo.save(acc);
    }

    public void delete(Long id) {
        repo.delete(id);
    }
}
