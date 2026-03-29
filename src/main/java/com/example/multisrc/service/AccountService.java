package com.example.multisrc.service;

import com.example.multisrc.model.Account;
import com.example.multisrc.repository.AccountRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AccountService {

    private final AccountRepository repo;

    @Value("${features.soft-delete:false}")
    private boolean softDeleteEnabled;

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
        acc.setName(updated.getName());
        return repo.save(acc);
    }

    public void delete(Long id) {
        Account acc = repo.findById(id).orElseThrow();

        if (softDeleteEnabled) {
            // Intentional S5 behavior:
            // feature flag changes delete semantics, but validation still expects hard delete.
            acc.setActive(false);
            repo.save(acc);
            return;
        }

        repo.deleteById(id);
    }
}
