package com.example.multisrc.service;

import com.example.multisrc.model.Account;
import com.example.multisrc.repository.AccountRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AccountService {

    private final AccountRepository repo;

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
        repo.delete(id);
    }
}
