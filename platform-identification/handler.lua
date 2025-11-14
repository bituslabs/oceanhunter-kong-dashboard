local PlatformIdentification = {
    PRIORITY = 802,
    VERSION = "1.0.0",
}

-- 平台特征参数集合
local platforms = {
    PA1 = {
        core = {"username", "pid", "gameid", "session"},
        optional = {"userFlag", "ip", "hideCurrency", "hideRTP"}
    },
    PA2 = {
        core = {"loginname", "gameID", "session"},
        optional = {"userFlag", "device"}
    },
    CP = {
        core = {"channelId", "pId", "playerName", "accessToken"},
        optional = {"gameId", "timestamp", "nickName", "userName"}
    }
}

-- 平台映射值
local platform_map = {
    PA1 = "1",
    PA2 = "1",
    CP  = "2"
}

-- 计算 table 长度
local function tableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- 计算 Dice 系数
local function diceCoefficient(featureSet, requestParams)
    if not featureSet or #featureSet == 0 then return 0 end
    local intersection = 0
    for _, key in ipairs(featureSet) do
        if requestParams[key] ~= nil then
            intersection = intersection + 1
        end
    end
    return 2 * intersection / (#featureSet + tableLength(requestParams))
end

-- 核心平台识别函数
local function detectPlatform(requestParams)
    local bestPlatform = "Unknown"
    local maxDice = 0

    for name, featureSet in pairs(platforms) do
        local dice_core = diceCoefficient(featureSet.core, requestParams)
        local dice_optional = diceCoefficient(featureSet.optional, requestParams)
        local totalDice = dice_core + 0.2 * dice_optional  -- 可选字段加权
        if totalDice > maxDice then
            maxDice = totalDice
            bestPlatform = name
        end
    end

    -- 阈值防止误判
    if maxDice < 0.2 then
        bestPlatform = "Unknown"
    end

    return bestPlatform, maxDice
end

-- 插件 access 阶段
function PlatformIdentification:access(conf)
    -- 获取请求参数 table
    local args = kong.request.get_query()

    -- 默认平台值
    local platform_value = "0"

    -- 调用平台识别
    local platform, score = detectPlatform(args)

    -- 映射平台值
    platform_value = platform_map[platform] or "0"

    -- 设置请求头
    kong.service.request.set_header("X-Platform", platform_value)

    -- 打印日志
    ngx.log(ngx.ERR, string.format(
        "PlatformIdentification plugin reached, platform=%s, platform_value=%s, score=%.3f",
        platform, platform_value, score
    ))
end

return PlatformIdentification
