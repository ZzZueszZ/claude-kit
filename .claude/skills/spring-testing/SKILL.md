---
name: Spring Testing
description: Hướng dẫn viết Unit Test và Integration Test chuẩn trong Spring Boot - JUnit 5, Mockito, TestContainers
---

# Spring Testing

Chuẩn hóa testing trong Spring Boot applications.

---

## 1. Test Structure & Naming

### Quy tắc bắt buộc
- Test class đặt cùng package với class được test
- Tên test class: `{ClassName}Test` (unit) hoặc `{ClassName}IntegrationTest`
- Tên test method: `should_{expected}_{when/given}_{condition}`
- Mỗi test chỉ test **1 behavior**
- Sử dụng **Given-When-Then** (Arrange-Act-Assert) pattern

### Template
```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private UserMapper userMapper;

    @InjectMocks
    private UserService userService;

    @Test
    @DisplayName("Should return user when user exists")
    void should_returnUser_when_userExists() {
        // Given (Arrange)
        Long userId = 1L;
        User user = createTestUser(userId);
        UserResponse expected = createTestUserResponse(userId);

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userMapper.toResponse(user)).thenReturn(expected);

        // When (Act)
        UserResponse actual = userService.getUser(userId);

        // Then (Assert)
        assertThat(actual).isNotNull();
        assertThat(actual.id()).isEqualTo(userId);
        assertThat(actual.username()).isEqualTo("testuser");

        verify(userRepository).findById(userId);
        verify(userMapper).toResponse(user);
    }

    @Test
    @DisplayName("Should throw ResourceNotFoundException when user not found")
    void should_throwNotFoundException_when_userNotFound() {
        // Given
        Long userId = 999L;
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        // When / Then
        assertThatThrownBy(() -> userService.getUser(userId))
            .isInstanceOf(ResourceNotFoundException.class)
            .hasMessageContaining("User not found");

        verify(userRepository).findById(userId);
        verifyNoInteractions(userMapper);
    }

    // Helper methods
    private User createTestUser(Long id) {
        return User.builder()
            .id(id)
            .username("testuser")
            .email("test@example.com")
            .build();
    }

    private UserResponse createTestUserResponse(Long id) {
        return new UserResponse(id, "testuser", "test@example.com",
            "Test User", List.of("USER"), LocalDateTime.now());
    }
}
```

---

## 2. Unit Test — Service Layer

### Quy tắc bắt buộc
- Dùng `@ExtendWith(MockitoExtension.class)` — KHÔNG dùng `@SpringBootTest`
- Mock tất cả dependencies
- Dùng **AssertJ** cho assertions (`assertThat`)
- Verify interactions với `verify()`

### Test cases cần có cho mỗi Service method

| Scenario | Ví dụ |
|----------|-------|
| Happy path | `should_createUser_when_validRequest` |
| Not found | `should_throwNotFoundException_when_userNotFound` |
| Duplicate | `should_throwDuplicateException_when_emailExists` |
| Validation | `should_throwException_when_invalidInput` |
| Edge cases | `should_handleEmptyList_when_noUsersFound` |

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock private UserRepository userRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private UserMapper userMapper;

    @InjectMocks private UserService userService;

    @Nested
    @DisplayName("createUser")
    class CreateUser {

        @Test
        @DisplayName("Should create user successfully")
        void should_createUser_when_validRequest() {
            // Given
            CreateUserRequest request = new CreateUserRequest(
                "john", "john@example.com", "Password123");
            User user = User.builder().username("john").email("john@example.com").build();
            User savedUser = User.builder().id(1L).username("john").email("john@example.com").build();
            UserResponse expected = new UserResponse(1L, "john", "john@example.com", null, List.of(), LocalDateTime.now());

            when(userRepository.existsByEmail("john@example.com")).thenReturn(false);
            when(userMapper.toEntity(request)).thenReturn(user);
            when(passwordEncoder.encode("Password123")).thenReturn("encoded");
            when(userRepository.save(user)).thenReturn(savedUser);
            when(userMapper.toResponse(savedUser)).thenReturn(expected);

            // When
            UserResponse actual = userService.createUser(request);

            // Then
            assertThat(actual.id()).isEqualTo(1L);
            assertThat(actual.username()).isEqualTo("john");

            verify(userRepository).existsByEmail("john@example.com");
            verify(userRepository).save(user);
        }

        @Test
        @DisplayName("Should throw DuplicateResourceException when email exists")
        void should_throwDuplicate_when_emailExists() {
            // Given
            CreateUserRequest request = new CreateUserRequest(
                "john", "existing@example.com", "Password123");
            when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

            // When / Then
            assertThatThrownBy(() -> userService.createUser(request))
                .isInstanceOf(DuplicateResourceException.class)
                .hasMessageContaining("email");

            verify(userRepository, never()).save(any());
        }
    }
}
```

---

## 3. Unit Test — Controller Layer

### Dùng `@WebMvcTest`
```java
@WebMvcTest(UserController.class)
@AutoConfigureMockMvc(addFilters = false) // Disable security for unit tests
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("GET /api/v1/users/{id} - Should return user")
    void should_returnUser_when_userExists() throws Exception {
        // Given
        Long userId = 1L;
        UserResponse response = new UserResponse(
            userId, "john", "john@example.com", "John Doe",
            List.of("USER"), LocalDateTime.now());

        when(userService.getUser(userId)).thenReturn(response);

        // When / Then
        mockMvc.perform(get("/api/v1/users/{id}", userId)
                .contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.id").value(userId))
            .andExpect(jsonPath("$.data.username").value("john"))
            .andExpect(jsonPath("$.data.email").value("john@example.com"));
    }

    @Test
    @DisplayName("POST /api/v1/users - Should create user")
    void should_createUser_when_validRequest() throws Exception {
        // Given
        CreateUserRequest request = new CreateUserRequest(
            "john", "john@example.com", "Password123");
        UserResponse response = new UserResponse(
            1L, "john", "john@example.com", null,
            List.of("USER"), LocalDateTime.now());

        when(userService.createUser(any())).thenReturn(response);

        // When / Then
        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.data.id").value(1L));
    }

    @Test
    @DisplayName("POST /api/v1/users - Should return 400 for invalid request")
    void should_return400_when_invalidRequest() throws Exception {
        // Given — missing required fields
        CreateUserRequest request = new CreateUserRequest("", "", "");

        // When / Then
        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.errorCode").value("VALIDATION_ERROR"))
            .andExpect(jsonPath("$.fieldErrors").isNotEmpty());
    }

    @Test
    @DisplayName("GET /api/v1/users/{id} - Should return 404 when not found")
    void should_return404_when_userNotFound() throws Exception {
        // Given
        when(userService.getUser(999L))
            .thenThrow(new ResourceNotFoundException("User", 999L));

        // When / Then
        mockMvc.perform(get("/api/v1/users/{id}", 999L))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
    }
}
```

---

## 4. Integration Test — Repository Layer

### Dùng `@DataJpaTest`
```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class UserRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @DynamicPropertySource
    static void overrideProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TestEntityManager entityManager;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("Should find user by email")
    void should_findUser_when_emailExists() {
        // Given
        User user = User.builder()
            .username("john")
            .email("john@example.com")
            .password("encoded_password")
            .status(UserStatus.ACTIVE)
            .build();
        entityManager.persistAndFlush(user);

        // When
        Optional<User> found = userRepository.findByEmail("john@example.com");

        // Then
        assertThat(found).isPresent();
        assertThat(found.get().getUsername()).isEqualTo("john");
    }

    @Test
    @DisplayName("Should return empty when email not found")
    void should_returnEmpty_when_emailNotFound() {
        // When
        Optional<User> found = userRepository.findByEmail("notexist@example.com");

        // Then
        assertThat(found).isEmpty();
    }
}
```

---

## 5. Integration Test — Full Stack

### Dùng `@SpringBootTest`
```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@AutoConfigureMockMvc
class UserIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
        .withDatabaseName("testdb");

    @DynamicPropertySource
    static void overrideProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("Full user lifecycle: create → get → update → delete")
    void should_completeUserLifecycle() throws Exception {
        // CREATE
        CreateUserRequest createRequest = new CreateUserRequest(
            "john", "john@example.com", "Password123");

        String createResponse = mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createRequest)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        Long userId = objectMapper.readTree(createResponse)
            .path("data").path("id").asLong();

        // GET
        mockMvc.perform(get("/api/v1/users/{id}", userId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.username").value("john"));

        // UPDATE
        UpdateUserRequest updateRequest = new UpdateUserRequest(
            "john_updated", null, "John Doe");

        mockMvc.perform(put("/api/v1/users/{id}", userId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(updateRequest)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.username").value("john_updated"));

        // DELETE
        mockMvc.perform(delete("/api/v1/users/{id}", userId))
            .andExpect(status().isNoContent());

        // VERIFY DELETED
        mockMvc.perform(get("/api/v1/users/{id}", userId))
            .andExpect(status().isNotFound());
    }
}
```

---

## 6. Test Utilities

### Test Data Builder
```java
public class TestDataFactory {

    public static User createUser() {
        return User.builder()
            .username("testuser")
            .email("test@example.com")
            .password("$2a$12$encoded_password")
            .fullName("Test User")
            .status(UserStatus.ACTIVE)
            .build();
    }

    public static User createUser(String username, String email) {
        return User.builder()
            .username(username)
            .email(email)
            .password("$2a$12$encoded_password")
            .status(UserStatus.ACTIVE)
            .build();
    }

    public static CreateUserRequest createUserRequest() {
        return new CreateUserRequest("testuser", "test@example.com", "Password123");
    }
}
```

### Custom assertions
```java
public class UserAssertions {
    public static void assertUserResponse(UserResponse actual,
                                           String expectedUsername,
                                           String expectedEmail) {
        assertThat(actual).isNotNull();
        assertThat(actual.id()).isNotNull();
        assertThat(actual.username()).isEqualTo(expectedUsername);
        assertThat(actual.email()).isEqualTo(expectedEmail);
    }
}
```

---

## 7. Testing Best Practices

### ✅ LUÔN
- Dùng **AssertJ** cho readable assertions
- Dùng `@Nested` để group related tests
- Dùng `@DisplayName` cho readable test names
- Test cả **happy path** và **error cases**
- **Isolate** tests — không depend lẫn nhau
- Dùng **TestContainers** cho database integration tests

### ❌ KHÔNG BAO GIỜ
- Test private methods trực tiếp
- Dùng `@SpringBootTest` cho unit tests (quá chậm)
- Hardcode test data trong test methods
- Test implementation details (chỉ test behavior)
- Skip error case tests - phải test cả exceptions

### Test Coverage
- Tối thiểu **80% line coverage** cho Service layer
- Tối thiểu **90% coverage** cho critical business logic
- Controller tests cover tất cả endpoints + validation cases

---

## Checklist trước khi commit

- [ ] Unit tests cho tất cả Service methods
- [ ] Controller tests cho tất cả endpoints
- [ ] Happy path + error cases covered
- [ ] Given-When-Then pattern nhất quán
- [ ] Assertions dùng AssertJ
- [ ] Test names rõ ràng, có `@DisplayName`
- [ ] Không có `@SpringBootTest` cho unit tests
- [ ] Integration tests dùng TestContainers
