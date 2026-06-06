using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using ShareDocApp.Backend.Auth;
using ShareDocApp.Backend.Common;
using ShareDocApp.Backend.Functions;
using ShareDocApp.Backend.Models;
using ShareDocApp.Backend.Models.Dtos;
using ShareDocApp.Backend.Storage;
using Xunit;

namespace ShareDocApp.Backend.Tests.Functions;

public class UsersFunctionTests
{
    private readonly Mock<IUserStore> _userStore = new();
    private readonly UsersFunction _func;
    private const string UserId = "test-oid-123";

    public UsersFunctionTests()
    {
        var auth = TestAuth.CreateValidator(UserId);
        _func = new UsersFunction(auth, _userStore.Object);
    }

    [Fact]
    public async Task Register_NewUser_CreatesAndReturns()
    {
        _userStore.Setup(s => s.GetAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserEntity?)null);
        _userStore.Setup(s => s.UpsertAsync(It.IsAny<UserEntity>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserEntity e, CancellationToken _) => e);

        var req = TestAuth.CreateRequest("POST");
        var result = await _func.Register(req, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<UserDto>(ok.Value);
        Assert.Equal(UserId, dto.Id);
        Assert.False(dto.PersistDocs);
    }

    [Fact]
    public async Task Register_ExistingUser_ReturnsExisting()
    {
        var existing = new UserEntity
        {
            RowKey = UserId,
            DisplayName = "Existing",
            Email = "e@test.com",
            PersistDocs = true,
            CreatedAt = DateTime.UtcNow
        };
        _userStore.Setup(s => s.GetAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(existing);

        var req = TestAuth.CreateRequest("POST");
        var result = await _func.Register(req, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<UserDto>(ok.Value);
        Assert.Equal("Existing", dto.DisplayName);
        Assert.True(dto.PersistDocs);
        _userStore.Verify(s => s.UpsertAsync(It.IsAny<UserEntity>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task GetMe_NotRegistered_Returns404()
    {
        _userStore.Setup(s => s.GetAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserEntity?)null);

        var req = TestAuth.CreateRequest("GET");
        var result = await _func.GetMe(req, CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(404, obj.StatusCode);
    }

    [Fact]
    public async Task GetMe_Registered_ReturnsUser()
    {
        _userStore.Setup(s => s.GetAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new UserEntity { RowKey = UserId, DisplayName = "Me" });

        var req = TestAuth.CreateRequest("GET");
        var result = await _func.GetMe(req, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<UserDto>(ok.Value);
        Assert.Equal("Me", dto.DisplayName);
    }

    [Fact]
    public async Task Register_NoAuth_Returns401()
    {
        var auth = TestAuth.CreateFailingValidator();
        var func = new UsersFunction(auth, _userStore.Object);
        var req = TestAuth.CreateRequestWithoutAuth("POST");

        var result = await func.Register(req, CancellationToken.None);

        var obj = Assert.IsType<ObjectResult>(result);
        Assert.Equal(401, obj.StatusCode);
    }
}
