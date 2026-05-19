package com.example.Sapo_Clone.Security.Jwt;

import com.example.Sapo_Clone.Entity.User;
import com.example.Sapo_Clone.Repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
@RequiredArgsConstructor
public class JwtService {

    private final UserRepository userRepository;

    // Secret and expiration loaded from application.properties — never hardcode in
    // source
    @Value("${jwt.secret}")
    private String secretKey;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    // -------------------------------------------------------------------------
    // Token generation — embeds userId, role, companyId, storeId as claims
    // -------------------------------------------------------------------------

    public String generateToken(String username, int companyId) {
        Map<String, Object> claims = new HashMap<>();

        User user = userRepository.findByUsernameAndCompany_Id(username, companyId)
                .orElseThrow(() -> new RuntimeException("User not found for token generation"));
        claims.put("userId", user.getId());
        claims.put("userFullName", user.getUserFullName());
        claims.put("userStatus", user.getUserStatus());
        claims.put("userRole", user.getRoles().getRolesName());
        claims.put("companyId", user.getCompany() != null ? user.getCompany().getId() : null);
        claims.put("storeId", user.getStore() != null ? user.getStore().getId() : null);

        return buildToken(claims, username + ":" + companyId);
    }

    private String buildToken(Map<String, Object> extraClaims, String username) {
        return Jwts.builder()
                .setClaims(extraClaims)
                .setSubject(username)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + jwtExpiration))
                .signWith(getSignInKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    private Key getSignInKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    // -------------------------------------------------------------------------
    // Claims extraction
    // -------------------------------------------------------------------------

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        return claimsResolver.apply(extractAllClaims(token));
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSignInKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    public Integer extractId(String token) {
        return extractClaim(token, claims -> (Integer) claims.get("userId"));
    }

    public Integer extractCompanyId(String token) {
        return extractClaim(token, claims -> (Integer) claims.get("companyId"));
    }

    public Integer extractStoreId(String token) {
        return extractClaim(token, claims -> (Integer) claims.get("storeId"));
    }

    public String extractRole(String token) {
        return extractClaim(token, claims -> (String) claims.get("userRole"));
    }

    // -------------------------------------------------------------------------
    // Validation
    // -------------------------------------------------------------------------

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    public boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return username.equals(userDetails.getUsername()) && !isTokenExpired(token);
    }
}