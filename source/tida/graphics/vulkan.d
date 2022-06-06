module tida.graphics.vulkan;

// TODO: implement vulkan backend

version(GraphBackendVulkan):

version(Posix)
{
    version(UseXCB)
    {

    } else
    {
        static assert(null, "Please, use version identifier `UseXCB` for work vulkan backend!");
    }
}

import erupted;
import tida.graphics.gapi;
import std.range : ElementType, isInputRange;
import std.string : toStringz;

alias cstr = char*;
alias ccstr = const(char*);

/++
Checking the result of the function execution for correctness. If the result
is different from normal, an exception will be thrown.

Params:
    result  =   Result of the function execution.
    message =   Checking the result of the function execution for correctness.
                If the result is different from normal, an exception will be
                thrown.
    file    =   The source code file in which the error occurred.
    line    =   The source code file in which the error occurred.
+/
void vkEnforce(
    VkResult result,
    string message = [],
    string file = __FILE__,
    int line = __LINE__
) @safe
{
    import std.conv : to;

    if (result != VkResult.VK_SUCCESS)
    {
        if (message.length == 0)
        {
            message = "Vulkan error: " ~ result.to!string;
        }

        throw new Exception(message, file, line);
    }
}


/// Information about a physical device, including properties and features.
struct PhysDeviceInfo
{
    VkPhysicalDeviceProperties devProp;
    VkPhysicalDeviceFeatures devFeat;
}

/// Information about a physical device, including properties and features.
struct QueueInfo
{
    uint index;
    VkQueueFamilyProperties properties;
    float priority = 1.0f;
    uint presentSupport;

    VkQueue handle;
}

final class VkSurface
{
    VkSurfaceKHR handle;
    VkContext context;
    VkSwapchainKHR swapchain;
    VkImage[] scImages;
    VkImageView[] scViewImages;
    VkFramebuffer[] scFramebuffers;

    SurfaceFormat format;

    this(VkContext context, VkSurfaceKHR surface) @safe
    {
        this.context = context;
        this.handle = surface;
    }

    void destroyFramebuffers() @trusted
    {
        if (scFramebuffers.length != 0)
        {
            foreach (ref e; scFramebuffers)
            {
                vkDestroyFramebuffer(context.device.logical, e, null);
            }

            scFramebuffers = [];
        }
    }

    void destroy() @trusted
    {
        if (scViewImages.length != 0)
        {
            foreach (ref e; scViewImages)
            {
                vkDestroyImageView(context.device.logical, e, null);
            }

            scViewImages = [];
        }
    }

    void destroySwapchain() @trusted
    {
        if (swapchain !is null)
        {
            vkDestroySwapchainKHR(context.device.logical, swapchain, null);
            swapchain = null;
        }
    }

    void destroyHandle() @trusted
    {
        if (handle !is null)
        {
            vkDestroySurfaceKHR(context.instance, handle, null);
            handle = null;
        }
    }
}

/++
An object for storing information and interacting with a device.
+/
final class VkDeviceHandle
{
public:
    VkPhysicalDevice physical;
    VkDevice logical;
    QueueInfo[] queues;

    this(VkPhysicalDevice physical) @trusted
    {
        this.physical = physical;
    }

    invariant
    {
        assert(physical);
    }

    /// Returns: An object for storing information and interacting with a device.
    PhysDeviceInfo physicalInfo() @trusted
    {
        PhysDeviceInfo devInfo;
        vkGetPhysicalDeviceProperties(physical, &devInfo.devProp);
        vkGetPhysicalDeviceFeatures(physical, &devInfo.devFeat);

        return devInfo;
    }

    void destroy() @trusted
    {
        if (logical !is null)
            vkDestroyDevice(logical, null);
    }

    ~this() @trusted
    {
        destroy();
    }
}

/++
Context for graphics. Purely executive functions.
+/
final class VkContext
{
public:
    VkInstance instance;
    VkDeviceHandle device;

    this(VkInstance instance) @safe
    {
        this.instance = instance;
    }

    invariant
    {
        assert(instance);
    }

    void destroy() @trusted
    {
        vkDestroyInstance(instance, null);
    }
}

auto vkExtensionsRange() @trusted
{
    import std.algorithm : map;
    import std.conv : to;

    uint extensionsCount = 0;
    VkExtensionProperties[] extensions;

    vkEnumerateInstanceExtensionProperties(null, &extensionsCount, null);
    extensions.length = extensionsCount;

    vkEnumerateInstanceExtensionProperties(null, &extensionsCount, extensions.ptr);

    static string rdExtInfo(VkExtensionProperties ext) @safe
    {
        size_t i = 0;
        while (ext.extensionName[++i] != '\0') { }

        return ext.extensionName[0 .. i].dup;
    }

    return map!rdExtInfo(extensions);
}

string[] vkExtensions(T)(T range) @safe
if (isInputRange!T && is(ElementType!T == string))
{
    import std.range : array;
    import std.algorithm : map;

    return vkExtensionsRange().array;
}

auto vkExtensionsCStr(T)(T range) @safe
if (isInputRange!T && is(ElementType!T == string))
{
    import std.range : array;
    import std.algorithm : map;

    return vkExtensionsRange().map!toStringz.array;
}

VkContext initVulkan(string applicationName) @trusted
{
    import lib = erupted.vulkan_lib_loader;

    VkInstance instance;

    lib.loadGlobalLevelFunctions();

    VkApplicationInfo applicationInfo;
    applicationInfo.pApplicationName = applicationName.toStringz;
    applicationInfo.pEngineName = "Tida".toStringz;
    applicationInfo.engineVersion = VK_MAKE_VERSION(0, 1, 3);
    applicationInfo.apiVersion = VK_API_VERSION_1_0;

    ccstr[] extensions;
    auto dextensions = vkExtensions(vkExtensionsRange());

    foreach (ext; dextensions)
    {
        extensions ~= ext.toStringz;
    }

    VkInstanceCreateInfo instanceInfo;
    instanceInfo.pApplicationInfo = &applicationInfo;
    instanceInfo.enabledExtensionCount = cast(uint) extensions.length;
    instanceInfo.ppEnabledExtensionNames = extensions.ptr;
    instanceInfo.enabledLayerCount = 0;

    vkEnforce(vkCreateInstance(&instanceInfo, null, &instance));

    loadInstanceLevelFunctions(instance);
    loadDeviceLevelFunctions(instance);

    return new VkContext(instance);
}

auto getDevices(VkContext context) @trusted
{
    static struct DeviceSetupRange
    {
        VkContext context;
        uint count;
        VkPhysicalDevice[] physical;

        uint index = 0;

        this(VkContext context) @trusted
        {
            this.context = context;

            vkEnumeratePhysicalDevices(context.instance, &count, null);
            physical.length = count;

            vkEnumeratePhysicalDevices(context.instance, &count, physical.ptr);
        }

        bool empty() @safe
        {
            return index == count;
        }

        void popFront() @safe
        {
            index++;
        }

        auto front() @trusted
        {
            return new VkDeviceHandle(physical[index]);
        }
    }

    return DeviceSetupRange(context);
}

auto getBestDevice(T)(T range) @trusted
if (isInputRange!T && is(ElementType!T == VkDeviceHandle))
{
    VkDeviceHandle result;
    uint resultScore;

    foreach (VkDeviceHandle e; range)
    {
        auto info = e.physicalInfo;
        uint score = 0;

        switch (info.devProp.deviceType)
        {
            case VK_PHYSICAL_DEVICE_TYPE_CPU:
                score += 100;
                break;

            case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU:
                score += 500;
                break;

            case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU:
                score += 1000;
                break;

            default: break;
        }

        score += info.devProp.limits.maxImageDimension2D;
        score += info.devProp.limits.maxVertexInputAttributes * 2;
        score += info.devFeat.geometryShader * 500;

        if (score > resultScore)
        {
            resultScore = score;
            result = e;
        }
    }

    return result;
}

void bindBestDevice(VkContext context) @safe
{
    context.device = getDevices(context).getBestDevice();
}

auto getQueuesDevice(VkDeviceHandle device) @safe
{
    static struct QueueRange
    {
        VkQueueFamilyProperties[] queueProps;
        uint count;
        uint index;

        this(VkDeviceHandle device) @trusted
        {
            vkGetPhysicalDeviceQueueFamilyProperties(device.physical, &count, null);
            queueProps.length = count;

            vkGetPhysicalDeviceQueueFamilyProperties(device.physical, &count, queueProps.ptr);
        }

        bool empty() @safe
        {
            return index == count;
        }

        void popFront() @safe
        {
            index++;
        }

        auto front() @safe
        {
            QueueInfo qInfo;
            qInfo.index = index;
            qInfo.properties = queueProps[index];

            return qInfo;
        }
    }

    return QueueRange(device);
}

void createLogical(Range)(VkDeviceHandle device, VkSurface surface, Range range) @trusted
if (isInputRange!Range && is(ElementType!Range == QueueInfo))
{
    VkDeviceQueueCreateInfo[] queuesCreateInfo;
    QueueInfo[] infos;

    foreach (QueueInfo e; range)
    {
        VkDeviceQueueCreateInfo qCreateInfo;
        qCreateInfo.queueFamilyIndex = e.index;
        qCreateInfo.queueCount = 1;
        qCreateInfo.pQueuePriorities = &e.priority;

        queuesCreateInfo ~= qCreateInfo;
        infos ~= e;
    }

    auto pInfo = device.physicalInfo;

    VkDeviceCreateInfo deviceInfo;
    deviceInfo.pQueueCreateInfos = queuesCreateInfo.ptr;
    deviceInfo.queueCreateInfoCount = cast(uint) queuesCreateInfo.length;
    deviceInfo.pEnabledFeatures = &pInfo.devFeat;

    vkEnforce(vkCreateDevice(device.physical, &deviceInfo, null, &device.logical));

    foreach (e; infos)
    {
        VkQueue queue;
        vkGetDeviceQueue(device.logical, e.index, 0, &queue);

        e.handle = queue;
        vkGetPhysicalDeviceSurfaceSupportKHR(device.physical, e.index, surface.handle, &e.presentSupport);

        device.queues ~= e;
    }
}

import tdw = tida.window;
import tida.runtime;

version(Posix)
{
    version(UseXCB)
    {
        mixin("
            import xcb.xcb;
            import erupted.platform_extensions;
            mixin Platform_Extensions!USE_PLATFORM_XCB_KHR;
        ");
    }
} else
version(Windows)
{
    mixin("
        import import core.sys.windows.windows;
        import erupted.platform_extensions;
        mixin Platform_Extensions!KHR_win32_surface;
    ");
}

version(Posix)
VkSurfaceKHR createSurfaceXCBImpl(VkContext context, tdw.Window window) @trusted
{
    VkSurfaceKHR surface;

    VkXcbSurfaceCreateInfoKHR surfaceInfo;
    surfaceInfo.connection = runtime.connection;
    surfaceInfo.window = window.handle;

    if (vkCreateXcbSurfaceKHR is null)
        throw new Exception("Module `VK_KHR_xcb_surface` is not a load!");

    vkEnforce(vkCreateXcbSurfaceKHR(context.instance, &surfaceInfo, null, &surface));

    return surface;
}

version(Windows)
VkSurfaceKHR createSurfaceWinImpl(VkContext context, tdw.Window window) @trusted
{
    VkSurfaceKHR surface;

    VkWin32SurfaceCreateInfoKHR surfaceInfo;
    surfaceInfo.hwnd = window.handle;
    surfaceInfo.hinstance = runtime.instance;

    vkEnforce(vkCreateWin32SurfaceKHR(contex.instance, &surfaceInfo, null, &surface));

    return surface;
}

VkSurface createSurface(VkContext context, tdw.Window window) @trusted
{
    VkSurfaceKHR surface;

    version(Posix)
    {
        surface = createSurfaceXCBImpl(context, window);
    } else
    version(Windows)
    {
        surface = createSurfaceWinImpl(context, window);
    }

    return new VkSurface(context, surface);
}

struct SurfaceSupportInfo
{
    VkSurfaceCapabilitiesKHR surfCap;
    VkSurfaceFormatKHR[] formats;
    VkPresentModeKHR[] modes;
}

SurfaceSupportInfo getSurfaceSupportInfo(VkDeviceHandle device, VkSurface surface) @trusted
{
    VkSurfaceCapabilitiesKHR surfCap;
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device.physical, surface.handle, &surfCap);

    uint count;
    VkSurfaceFormatKHR[] formats;
    VkPresentModeKHR[] modes;

    vkGetPhysicalDeviceSurfaceFormatsKHR(device.physical, surface.handle, &count, null);
    formats.length = count;
    vkGetPhysicalDeviceSurfaceFormatsKHR(device.physical, surface.handle, &count, formats.ptr);

    vkGetPhysicalDeviceSurfacePresentModesKHR(device.physical, surface.handle, &count, null);
    modes.length = count;
    vkGetPhysicalDeviceSurfacePresentModesKHR(device.physical, surface.handle, &count, modes.ptr);

    return SurfaceSupportInfo(surfCap, formats, modes);
}

auto vkFormatFromAttribs(
    GraphicsAttributes attribs
) @safe
{
    if (attribs.redSize == 4 && attribs.greenSize == 4 && attribs.blueSize == 0 && attribs.colorDepth == 8)
        return VK_FORMAT_R4G4_UNORM_PACK8;
    else
    if (attribs.redSize == 4 && attribs.greenSize == 4 && attribs.blueSize == 4 && attribs.colorDepth == 16)
        return VK_FORMAT_R4G4B4A4_UNORM_PACK16;
    else
    if (attribs.redSize == 5 && attribs.greenSize == 6 && attribs.blueSize == 5 && attribs.colorDepth == 16)
        return VK_FORMAT_R5G6B5_UNORM_PACK16;
    else
    if (attribs.redSize == 5 && attribs.greenSize == 5 && attribs.blueSize == 5 && attribs.alphaSize == 1 &&
        attribs.colorDepth == 16)
        return VK_FORMAT_R5G5B5A1_UNORM_PACK16;
    else
    if (attribs.redSize == 8 && attribs.greenSize == 0 && attribs.blueSize == 0 && attribs.alphaSize == 0)
        return VK_FORMAT_R8_SRGB;
    else
    if (attribs.redSize == 8 && attribs.greenSize == 8 && attribs.blueSize == 0 && attribs.alphaSize == 0)
        return VK_FORMAT_R8G8_SRGB;
    else
    if (attribs.redSize == 8 && attribs.greenSize == 8 && attribs.blueSize == 8 && attribs.alphaSize == 0)
        return VK_FORMAT_R8G8B8_SRGB;
    else
    if (attribs.redSize == 8 && attribs.greenSize == 8 && attribs.blueSize == 8 && attribs.alphaSize == 8)
        return VK_FORMAT_R8G8B8A8_SRGB;
    else
    if (attribs.redSize == 16 && attribs.greenSize == 0 && attribs.blueSize == 0 && attribs.alphaSize == 0)
        return VK_FORMAT_R16_SFLOAT;
    else
    if (attribs.redSize == 16 && attribs.greenSize == 16 && attribs.blueSize == 0 && attribs.alphaSize == 0)
        return VK_FORMAT_R16G16_SFLOAT;
    else
    if (attribs.redSize == 16 && attribs.greenSize == 16 && attribs.blueSize == 16 && attribs.alphaSize == 0)
        return VK_FORMAT_R16G16B16_SFLOAT;
    else
    if (attribs.redSize == 16 && attribs.greenSize == 16 && attribs.blueSize == 16 && attribs.alphaSize == 16)
        return VK_FORMAT_R16G16B16A16_SFLOAT;
    else
    if (attribs.redSize == 32 && attribs.greenSize == 0 && attribs.blueSize == 0 && attribs.alphaSize == 0)
        return VK_FORMAT_R32_SFLOAT;
    else
    if (attribs.redSize == 32 && attribs.greenSize == 16 && attribs.blueSize == 0 && attribs.alphaSize == 0)
        return VK_FORMAT_R32G32_SFLOAT;
    else
    if (attribs.redSize == 32 && attribs.greenSize == 16 && attribs.blueSize == 32 && attribs.alphaSize == 0)
        return VK_FORMAT_R32G32B32_SFLOAT;
    else
    if (attribs.redSize == 32 && attribs.greenSize == 32 && attribs.blueSize == 32 && attribs.alphaSize == 32)
        return VK_FORMAT_R32G32B32A32_SFLOAT;
    else
    if (attribs.redSize == 64 && attribs.greenSize == 0 && attribs.blueSize == 0 && attribs.alphaSize == 0)
        return VK_FORMAT_R64_SFLOAT;
    else
    if (attribs.redSize == 64 && attribs.greenSize == 64 && attribs.blueSize == 0 && attribs.alphaSize == 0)
        return VK_FORMAT_R64G64_SFLOAT;
    else
    if (attribs.redSize == 64 && attribs.greenSize == 64 && attribs.blueSize == 64 && attribs.alphaSize == 0)
        return VK_FORMAT_R64G64B64_SFLOAT;
    else
    if (attribs.redSize == 64 && attribs.greenSize == 64 && attribs.blueSize == 64 && attribs.alphaSize == 64)
        return VK_FORMAT_R64G64B64A64_SFLOAT;

    return VK_FORMAT_UNDEFINED;
}

struct SurfaceFormat
{
    VkSurfaceFormatKHR format;
    VkExtent2D extend;
}

auto choiceSwapSurfaceFormat(
    VkSurface surface,
    VkDeviceHandle device,
    SurfaceSupportInfo supportInfo,
    GraphicsAttributes attribs,
    tdw.IWindow window,
    VkSwapchainKHR oldSwapchain = null
) @trusted
{
    import std.algorithm : canFind;

    VkSurfaceFormatKHR bestFormat;
    auto needFormat = vkFormatFromAttribs(attribs);

    foreach (e; supportInfo.formats)
    {
        if (e.format == needFormat &&
            e.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
        {
            bestFormat = e;
        }
    }

    if (bestFormat == VkSurfaceFormatKHR.init)
        bestFormat = supportInfo.formats[0];

    VkPresentModeKHR bufferMode;
    if (attribs.bufferMode == BufferMode.singleBuffer)
        bufferMode = VK_PRESENT_MODE_IMMEDIATE_KHR;
    else
    if (attribs.bufferMode == BufferMode.doubleBuffer)
        bufferMode = VK_PRESENT_MODE_FIFO_KHR;
    else
    if (attribs.bufferMode == BufferMode.troubleBuffer)
        bufferMode = VK_PRESENT_MODE_MAILBOX_KHR;

    if (!supportInfo.modes.canFind(bufferMode))
        bufferMode = supportInfo.modes[0];

    uint imageCount = supportInfo.surfCap.minImageCount + 1;
    VkExtent2D extend = VkExtent2D(
        window.width, window.height
    );

    if (extend.width > supportInfo.surfCap.maxImageExtent.width)
        extend.width = supportInfo.surfCap.maxImageExtent.width;

    if (extend.width < supportInfo.surfCap.minImageExtent.width)
        extend.width = supportInfo.surfCap.minImageExtent.width;

    if (extend.height > supportInfo.surfCap.maxImageExtent.height)
        extend.height = supportInfo.surfCap.maxImageExtent.height;

    if (extend.height < supportInfo.surfCap.minImageExtent.height)
        extend.height = supportInfo.surfCap.minImageExtent.height;

    surface.format = SurfaceFormat(bestFormat, extend);

    VkSwapchainCreateInfoKHR scInfo;
    scInfo.surface = surface.handle;
    scInfo.minImageCount = imageCount;
    scInfo.imageFormat = bestFormat.format;
    scInfo.imageColorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
    scInfo.imageExtent = extend;
    scInfo.imageArrayLayers = 1;
    scInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;

    QueueInfo graph, present;

    foreach(e; device.queues)
    {
        if (e.properties.queueFlags & VK_QUEUE_GRAPHICS_BIT)
        {
            graph = e;
        }

        if (e.presentSupport)
        {
            present = e;
        }
    }

    if (graph.index == present.index)
    {
        scInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    } else
    {
        scInfo.imageSharingMode = VK_SHARING_MODE_CONCURRENT;
        scInfo.queueFamilyIndexCount = 2;
        scInfo.pQueueFamilyIndices = [graph.index, present.index].ptr;
    }

    scInfo.preTransform = supportInfo.surfCap.currentTransform;
    scInfo.presentMode = bufferMode;
    scInfo.clipped = true;
    scInfo.oldSwapchain = oldSwapchain;

    vkEnforce(vkCreateSwapchainKHR(device.logical, &scInfo, null, &surface.swapchain));

    uint icount = 0;
    vkGetSwapchainImagesKHR(device.logical, surface.swapchain, &icount, null);
    surface.scImages.length = icount;
    vkGetSwapchainImagesKHR(device.logical, surface.swapchain, &icount, surface.scImages.ptr);

    surface.scViewImages.length = surface.scImages.length;

    foreach (i; 0 .. surface.scViewImages.length)
    {
        VkImageViewCreateInfo ivInfo;
        ivInfo.image = surface.scImages[i];
        ivInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
        ivInfo.format = bestFormat.format;
        ivInfo.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
        ivInfo.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
        ivInfo.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
        ivInfo.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;

        ivInfo.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        ivInfo.subresourceRange.baseMipLevel = 0;
        ivInfo.subresourceRange.levelCount = 1;
        ivInfo.subresourceRange.baseArrayLayer = 0;
        ivInfo.subresourceRange.layerCount = 1;

        vkEnforce(
            vkCreateImageView(device.logical, &ivInfo, null, &surface.scViewImages[i])
        );
    }
}

class VulkanBuffer : IBuffer
{
override:
    /// How to use buffer.
    void usage(BufferType _type) @safe
    {

    }

    /// Buffer type.
    @property BufferType type() @safe inout
    {
        return BufferType.array;
    }

    /// Specifying the buffer how it will be used.
    void dataUsage(BuffUsageType usageType) @safe
    {

    }

    /// Attach data to buffer. If the data is created as immutable, the data can
    /// only be entered once.
    void bindData(void[] data) @safe
    {

    }

    /// ditto
    void bindData(void[] data) @safe immutable
    {

    }

    /// Clears data. If the data is immutable, then the method will throw an
    /// exception.
    void clear() @safe
    {

    }
}

class VulkanVertexBuffer : IVertexInfo
{
override:
    /// Attach a buffer to an object.
    void bindBuffer(inout IBuffer) @safe
    {

    }

    /// Describe the binding of the buffer to the vertices.
    void vertexAttribPointer(AttribPointerInfo[]) @safe
    {

    }
}

class VulkanTexture : ITexture
{
override:
    void append(inout void[] data, uint width, uint height) @safe
    {

    }

    void wrap(TextureWrap wrap, TextureWrapValue value) @safe
    {

    }

    void filter(TextureFilter filter, TextureFilterValue value) @safe
    {

    }

    void active(uint value) @safe
    {

    }
}

class VulkanShaderManip : IShaderManip
{
    VkShaderModule shaderModule;
    VkDevice device;
    StageType _stage;
    VkPipelineShaderStageCreateInfo stInfo;

    this(VkDevice device, StageType _stage) @trusted
    {
        this.device = device;
        this._stage = _stage;
    }

    ~this() @trusted
    {
        vkDestroyShaderModule(device, shaderModule, null);
    }

override:
    void loadFromSource(string file) @trusted
    {

    }

    void loadFromMemory(void[] memory) @trusted
    {
        VkShaderModuleCreateInfo createInfo;
        createInfo.codeSize = memory.length;
        createInfo.pCode = cast(uint*) memory.ptr;

        vkEnforce(vkCreateShaderModule(device, &createInfo, null, &shaderModule));

        if (stage == StageType.vertex)
        {
            stInfo.stage = VK_SHADER_STAGE_VERTEX_BIT;
        } else
        if (stage == StageType.fragment)
        {
            stInfo.stage = VK_SHADER_STAGE_FRAGMENT_BIT;
        } else
        if (stage == StageType.geometry)
        {
            stInfo.stage = VK_SHADER_STAGE_GEOMETRY_BIT;
        }

        stInfo._module = shaderModule;
        stInfo.pName = "main";
    }

    @property StageType stage() @safe
    {
        return _stage;
    }
}

class VulkanShaderProgram : IShaderProgram
{
    VkContext context;
    VkSurface surface;

    VkPipelineDynamicStateCreateInfo dynInfo;
    VkPipelineRasterizationStateCreateInfo rasterInfo;
    VkPipelineMultisampleStateCreateInfo mutsamInfo;

    VkPipelineLayout playout;

    VkPipelineVertexInputStateCreateInfo viInfo;
    VkPipelineInputAssemblyStateCreateInfo iaInfo;

    VkViewport vport;
    VkRect2D scissor;
    VkPipelineColorBlendStateCreateInfo bInfo;

    VkRenderPass renderPass;

    VkGraphicsPipelineCreateInfo gpInfo;

    VulkanShaderManip vertex;
    VulkanShaderManip fragment;

    VkPipeline pipeline;

    this(
        VkContext context,
        VkSurface surface,
        VkViewport vport,
        VkRect2D scissor,
        VkPipelineColorBlendStateCreateInfo bInfo,
        VkRenderPass renderPass
    ) @trusted
    {
        this.context = context;
        this.surface = surface;
        this.vport = vport;
        this.scissor = scissor;
        this.bInfo = bInfo;
        this.renderPass = renderPass;
    }

    void destroy() @trusted
    {
        if (pipeline !is null)
        {
            vkDestroyPipeline(context.device.logical, pipeline, null);
        }

        if (playout !is null)
        {
            vkDestroyPipelineLayout(context.device.logical, playout, null);
        }
    }

    ~this() @trusted
    {
        destroy();
    }

    override void attach(IShaderManip shader) @safe
    {
        if (shader.stage == StageType.vertex)
            vertex = cast(VulkanShaderManip) shader;
        else
        if (shader.stage == StageType.fragment)
            fragment = cast(VulkanShaderManip) shader;
    }

    override void link() @safe
    {
        if (vertex is null || fragment is null)
            throw new Exception("Link witout vertex or fragment is impassabal!");

        this.update();
    }

    void update() @trusted
    {
        immutable states = [
            VkDynamicState.VK_DYNAMIC_STATE_VIEWPORT,
            VkDynamicState.VK_DYNAMIC_STATE_LINE_WIDTH,
            VkDynamicState.VK_DYNAMIC_STATE_SCISSOR
        ];

        dynInfo.dynamicStateCount = cast(uint) states.length;
        dynInfo.pDynamicStates = states.ptr;

        VkPipelineLayoutCreateInfo plInfo;
        plInfo.setLayoutCount = 0;
        plInfo.pSetLayouts = null;
        plInfo.pushConstantRangeCount = 0;
        plInfo.pPushConstantRanges = null;

        vkEnforce(
            vkCreatePipelineLayout(context.device.logical, &plInfo, null, &playout)
        );

        rasterInfo.depthClampEnable = VK_FALSE;
        rasterInfo.rasterizerDiscardEnable = VK_FALSE;
        rasterInfo.polygonMode = VK_POLYGON_MODE_FILL;
        rasterInfo.lineWidth = 1.0f;
        rasterInfo.cullMode = VK_CULL_MODE_BACK_BIT;
        rasterInfo.frontFace = VK_FRONT_FACE_CLOCKWISE;
        rasterInfo.depthBiasEnable = VK_FALSE;

        mutsamInfo.sampleShadingEnable = VK_FALSE;
        mutsamInfo.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;

        viInfo.vertexBindingDescriptionCount = 0;
        viInfo.vertexAttributeDescriptionCount = 0;

        iaInfo.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
        iaInfo.primitiveRestartEnable = VK_FALSE;

        auto shaderStages = [vertex.stInfo, fragment.stInfo];

        VkPipelineViewportStateCreateInfo viewportState;
        viewportState.viewportCount = 1;
        viewportState.pViewports = &vport;
        viewportState.scissorCount = 1;
        viewportState.pScissors = &scissor;

        gpInfo.stageCount = 2;
        gpInfo.pStages = shaderStages.ptr;
        gpInfo.pVertexInputState = &viInfo;
        gpInfo.pInputAssemblyState = &iaInfo;
        gpInfo.pViewportState = &viewportState;
        gpInfo.pRasterizationState = &rasterInfo;
        gpInfo.pMultisampleState = &mutsamInfo;
        gpInfo.pColorBlendState = &bInfo;
        gpInfo.layout = playout;
        gpInfo.renderPass = renderPass;
        gpInfo.subpass = 0;
        gpInfo.basePipelineHandle = VK_NULL_HANDLE;

        vkEnforce(
            vkCreateGraphicsPipelines(
                context.device.logical, null, 1, &gpInfo, null, &pipeline
            )
        );
    }

override:
    uint getUniformID(string name) @safe
    {

    }

    /// Sets the value to the uniform.
    void setUniform(uint uniformID, float value) @safe
    {

    }

    /// ditto
    void setUniform(uint uniformID, uint value) @safe
    {

    }

    /// ditto
    void setUniform(uint uniformID, int value) @safe
    {

    }

    /// ditto
    void setUniform(uint uniformID, float[2] value) @safe
    {

    }

    /// ditto
    void setUniform(uint uniformID, float[3] value) @safe
    {

    }

    /// ditto
    void setUniform(uint uniformID, float[4] value) @safe
    {

    }

    /// ditto
    void setUniform(uint uniformID, float[2][2] value) @safe
    {

    }

    /// ditto
    void setUniform(uint uniformID, float[3][3] value) @safe
    {

    }

    /// ditto
    void setUniform(uint uniformID, float[4][4] value) @safe
    {

    }
}

auto blendConv(BlendFactor factor) @safe
{
    if (factor == BlendFactor.Zero)
        return VK_BLEND_FACTOR_ZERO;
    else
    if (factor == BlendFactor.One)
        return VK_BLEND_FACTOR_ONE;
    else
    if (factor == BlendFactor.SrcColor)
        return VK_BLEND_FACTOR_SRC_COLOR;
    else
    if (factor == BlendFactor.OneMinusSrcColor)
        return VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR;
    else
    if (factor == BlendFactor.DstColor)
        return VK_BLEND_FACTOR_DST_COLOR;
    else
    if (factor == BlendFactor.OneMinusDstColor)
        return VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR;
    else
    if (factor == BlendFactor.SrcAlpha)
        return VK_BLEND_FACTOR_SRC_ALPHA;
    else
    if (factor == BlendFactor.OneMinusSrcAlpha)
        return VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    else
    if (factor == BlendFactor.DstAlpha)
        return VK_BLEND_FACTOR_DST_ALPHA;
    else
    if (factor == BlendFactor.OneMinusDstAlpha)
        return VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA;
    else
    if (factor == BlendFactor.ConstantColor)
        return VK_BLEND_FACTOR_CONSTANT_COLOR;
    else
    if (factor == BlendFactor.OneMinusConstantColor)
        return VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR;
    else
    if (factor == BlendFactor.ConstantAlpha)
        return VK_BLEND_FACTOR_CONSTANT_ALPHA;
    else
    if (factor == BlendFactor.OneMinusConstanceAlpha)
        return VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA;

    return 0;
}

/++
Implementation graphics manipulator vulkan.
+/
class VulkanGraphManup : IGraphManip
{
    import tida.window;

    VkContext context;
    VkSurface surface;
    VkViewport vport;
    VkRect2D scissor;
    SurfaceSupportInfo surfSuppInfo;
    Window window;
    GraphicsAttributes attribs;

    VkPipelineColorBlendAttachmentState blendState;
    VkPipelineColorBlendStateCreateInfo bInfo;

    VkAttachmentDescription attachInfo;
    VkAttachmentReference attachRef;
    VkSubpassDescription subpInfo;

    VulkanShaderProgram[] programs;
    VulkanShaderProgram currProgram;

    VkRenderPassCreateInfo rpInfo;
    VkRenderPass renderPass;
    VkClearValue clrColor = VkClearValue(VkClearColorValue([0f, 0f, 0f, 1f]));

    VkSemaphore imgAval,
                renFinl;
    VkFence     flFence;

    QueueInfo   queueGraph,
                queuePresent;

    VkCommandPool cmdPool;
    VkCommandBuffer[] cmdBuff;

    uint imageIndex = 0;

    ~this() @trusted
    {
        if (imgAval !is null)
        {
            vkDestroySemaphore(context.device.logical, imgAval, null);
            imgAval = null;
        }

        if (renFinl !is null)
        {
            vkDestroySemaphore(context.device.logical, renFinl, null);
            renFinl = null;
        }

        if (flFence !is null)
        {
            vkDestroyFence(context.device.logical, flFence, null);
            flFence = null;
        }

        if (cmdPool !is null)
        {
            vkDestroyCommandPool(context.device.logical, cmdPool, null);
            cmdPool = null;
        }

        surface.destroyFramebuffers();

        if (renderPass !is null)
        {
            vkDestroyRenderPass(context.device.logical, renderPass, null);
            renderPass = null;
        }

        surface.destroyHandle();

        surface.destroy();
        context.destroy();
    }

override:
    void initialize() @safe
    {
        context = initVulkan("TidaTest");
        bindBestDevice(context);
    }

    void createAndBindSurface(Window window, GraphicsAttributes attribs) @trusted
    {
        this.window = window;
        this.attribs = attribs;
        surface = createSurface(context, window);

        auto queue = getQueuesDevice(context.device);
        createLogical(context.device, surface, queue);

        surfSuppInfo = getSurfaceSupportInfo(context.device, surface);

        choiceSwapSurfaceFormat(
            surface,
            context.device,
            surfSuppInfo,
            attribs,
            window
        );

        vport.x = 0.0f;
        vport.y = 0.0f;
        vport.width = window.width;
        vport.height = window.height;
        vport.minDepth = 0.0f;
        vport.maxDepth = 1.0f;

        scissor.offset = VkOffset2D(0, 0);
        scissor.extent = VkExtent2D(window.width, window.height);

        attachInfo.format = surface.format.format.format;
        attachInfo.samples = VK_SAMPLE_COUNT_1_BIT;
        attachInfo.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
        attachInfo.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
        attachInfo.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        attachInfo.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        attachInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
        attachInfo.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

        attachRef.attachment = 0;
        attachRef.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

        subpInfo.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
        subpInfo.colorAttachmentCount = 1;
        subpInfo.pColorAttachments = &attachRef;

        rpInfo.attachmentCount = 1;
        rpInfo.pAttachments = &attachInfo;
        rpInfo.subpassCount = 1;
        rpInfo.pSubpasses = &subpInfo;

        vkEnforce(vkCreateRenderPass(
            context.device.logical,
            &rpInfo,
            null,
            &renderPass
        ));

        surface.scFramebuffers.length = surface.scViewImages.length;
        foreach (i; 0 .. surface.scViewImages.length)
        {
            VkImageView[] attachments = [
                surface.scViewImages[i]
            ];

            VkFramebufferCreateInfo framebufferInfo;
            framebufferInfo.renderPass = renderPass;
            framebufferInfo.attachmentCount = 1;
            framebufferInfo.pAttachments = attachments.ptr;
            framebufferInfo.width = window.width;
            framebufferInfo.height = window.height;
            framebufferInfo.layers = 1;

            vkEnforce(
                vkCreateFramebuffer(
                    context.device.logical,
                    &framebufferInfo,
                    null,
                    &surface.scFramebuffers[i]
                )
            );
        }

        foreach (i; 0 .. context.device.queues.length)
        {
            if (context.device.queues[i].properties.queueFlags & VK_QUEUE_GRAPHICS_BIT)
            {
                queueGraph = context.device.queues[i];
            }

            if (context.device.queues[i].presentSupport)
            {
                queuePresent = context.device.queues[i];
            }
        }

        VkCommandPoolCreateInfo plInfo;
        plInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
        plInfo.queueFamilyIndex = queueGraph.index;

        vkEnforce(
            vkCreateCommandPool(
                context.device.logical,
                &plInfo,
                null,
                &cmdPool
            )
        );

        cmdBuff.length = surface.scFramebuffers.length;
        VkCommandBufferAllocateInfo caInfo;
        caInfo.commandPool = cmdPool;
        caInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
        caInfo.commandBufferCount = cast(uint) cmdBuff.length;

        vkEnforce(
            vkAllocateCommandBuffers(
                context.device.logical,
                &caInfo,
                cmdBuff.ptr
            )
        );

        foreach (ref e; cmdBuff)
        {
            VkCommandBufferBeginInfo beInfo;
            beInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
            beInfo.flags = 0;
            beInfo.pInheritanceInfo = null;

            vkBeginCommandBuffer(e, &beInfo);
        }

        VkSemaphoreCreateInfo smpInfo;
        VkFenceCreateInfo fncInfo;
        fncInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;

        vkEnforce(vkCreateSemaphore(context.device.logical, &smpInfo, null, &imgAval));
        vkEnforce(vkCreateSemaphore(context.device.logical, &smpInfo, null, &renFinl));
        vkEnforce(vkCreateFence(context.device.logical, &fncInfo, null, &flFence));
    }

    void update() @trusted
    {
        vkDeviceWaitIdle(context.device.logical);

        if (imgAval !is null)
        {
            vkDestroySemaphore(context.device.logical, imgAval, null);
            imgAval = null;
        }

        if (renFinl !is null)
        {
            vkDestroySemaphore(context.device.logical, renFinl, null);
            renFinl = null;
        }

        if (flFence !is null)
        {
            vkDestroyFence(context.device.logical, flFence, null);
            flFence = null;
        }

        if (cmdPool !is null)
        {
            vkDestroyCommandPool(context.device.logical, cmdPool, null);
            cmdPool = null;
        }

        surface.destroyFramebuffers();

        if (renderPass !is null)
        {
            vkDestroyRenderPass(context.device.logical, renderPass, null);
            renderPass = null;
        }

        surface.destroy();

        //surfSuppInfo = getSurfaceSupportInfo(context.device, surface);

        choiceSwapSurfaceFormat(
            surface,
            context.device,
            surfSuppInfo,
            attribs,
            window,
            surface.swapchain
        );

        vport.x = 0.0f;
        vport.y = 0.0f;
        vport.width = window.width;
        vport.height = window.height;
        vport.minDepth = 0.0f;
        vport.maxDepth = 1.0f;

        scissor.offset = VkOffset2D(0, 0);
        scissor.extent = VkExtent2D(window.width, window.height);

        attachInfo.format = surface.format.format.format;
        attachInfo.samples = VK_SAMPLE_COUNT_1_BIT;
        attachInfo.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
        attachInfo.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
        attachInfo.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        attachInfo.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        attachInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
        attachInfo.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

        attachRef.attachment = 0;
        attachRef.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

        subpInfo.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
        subpInfo.colorAttachmentCount = 1;
        subpInfo.pColorAttachments = &attachRef;

        rpInfo.attachmentCount = 1;
        rpInfo.pAttachments = &attachInfo;
        rpInfo.subpassCount = 1;
        rpInfo.pSubpasses = &subpInfo;

        vkEnforce(vkCreateRenderPass(
            context.device.logical,
            &rpInfo,
            null,
            &renderPass
        ));

        surface.scFramebuffers.length = surface.scViewImages.length;
        foreach (i; 0 .. surface.scViewImages.length)
        {
            VkImageView[] attachments = [
                surface.scViewImages[i]
            ];

            VkFramebufferCreateInfo framebufferInfo;
            framebufferInfo.renderPass = renderPass;
            framebufferInfo.attachmentCount = 1;
            framebufferInfo.pAttachments = attachments.ptr;
            framebufferInfo.width = window.width;
            framebufferInfo.height = window.height;
            framebufferInfo.layers = 1;

            vkEnforce(
                vkCreateFramebuffer(
                    context.device.logical,
                    &framebufferInfo,
                    null,
                    &surface.scFramebuffers[i]
                )
            );
        }

        VkCommandPoolCreateInfo plInfo;
        plInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
        plInfo.queueFamilyIndex = queueGraph.index;

        vkEnforce(
            vkCreateCommandPool(
                context.device.logical,
                &plInfo,
                null,
                &cmdPool
            )
        );

        cmdBuff.length = surface.scFramebuffers.length;
        VkCommandBufferAllocateInfo caInfo;
        caInfo.commandPool = cmdPool;
        caInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
        caInfo.commandBufferCount = cast(uint) cmdBuff.length;

        vkEnforce(
            vkAllocateCommandBuffers(
                context.device.logical,
                &caInfo,
                cmdBuff.ptr
            )
        );

        foreach (ref e; cmdBuff)
        {
            VkCommandBufferBeginInfo beInfo;
            beInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
            beInfo.flags = 0;
            beInfo.pInheritanceInfo = null;

            vkBeginCommandBuffer(e, &beInfo);
        }

        VkSemaphoreCreateInfo smpInfo;
        VkFenceCreateInfo fncInfo;
        fncInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;

        vkEnforce(vkCreateSemaphore(context.device.logical, &smpInfo, null, &imgAval));
        vkEnforce(vkCreateSemaphore(context.device.logical, &smpInfo, null, &renFinl));
        vkEnforce(vkCreateFence(context.device.logical, &fncInfo, null, &flFence));
    }

    void clearColor(Color!ubyte color) @trusted
    {
        clrColor = VkClearValue(VkClearColorValue([color.rf, color.gf, color.bf, color.af]));
    }

    void viewport(float x, float y, float w, float h) @trusted
    {
        vport.x = x;
        vport.y = y;
        vport.width = w;
        vport.height = h;
        vport.minDepth = 0.0f;
        vport.maxDepth = 1.0f;

        scissor.offset = VkOffset2D(cast(int) x, cast(int) y);
        scissor.extent = VkExtent2D(cast(int) w, cast(int) h);
    }

    void blendFactor(BlendFactor src, BlendFactor dst, bool state) @trusted
    {
        VkBlendFactor vSrc = cast(VkBlendFactor) blendConv(src);
        VkBlendFactor vDst = cast(VkBlendFactor) blendConv(dst);

        blendState.colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT | VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;
        blendState.blendEnable = state;
        blendState.srcColorBlendFactor = vSrc;
        blendState.dstColorBlendFactor = vDst;
        blendState.colorBlendOp = VK_BLEND_OP_ADD;
        blendState.srcAlphaBlendFactor = vSrc;
        blendState.dstAlphaBlendFactor = vDst;
        blendState.alphaBlendOp = VK_BLEND_OP_ADD;

        bInfo.logicOpEnable = VK_FALSE;
        bInfo.logicOp = VK_LOGIC_OP_COPY; // Optional
        bInfo.attachmentCount = 1;
        bInfo.pAttachments = &blendState;
        bInfo.blendConstants[0] = 0.0f; // Optional
        bInfo.blendConstants[1] = 0.0f; // Optional
        bInfo.blendConstants[2] = 0.0f; // Optional
        bInfo.blendConstants[3] = 0.0f; // Optional
    }

    void begin() @trusted
    {
        vkWaitForFences(context.device.logical, 1, &flFence, true, uint64_t.max);
        vkResetFences(context.device.logical, 1, &flFence);

        vkAcquireNextImageKHR(context.device.logical, surface.swapchain, uint64_t.max, imgAval, null, &imageIndex);
        vkResetCommandBuffer(cmdBuff[imageIndex], 0);

        VkRenderPassBeginInfo rbInfo;
        rbInfo.renderPass = renderPass;
        rbInfo.framebuffer = surface.scFramebuffers[imageIndex];
        rbInfo.renderArea.offset = VkOffset2D(0, 0);
        rbInfo.renderArea.extent = scissor.extent;
        rbInfo.clearValueCount = 1;
        rbInfo.pClearValues = &clrColor;

        vkCmdBeginRenderPass(cmdBuff[imageIndex], &rbInfo, VK_SUBPASS_CONTENTS_INLINE);
        vkCmdBindPipeline(cmdBuff[imageIndex], VK_PIPELINE_BIND_POINT_GRAPHICS, currProgram.pipeline);
    }

    void bindProgram(IShaderProgram program) @trusted
    {
        currProgram = cast(VulkanShaderProgram) program;
    }

    void draw(ModeDraw mode, uint first, uint count) @trusted
    {
        vkCmdDraw(cmdBuff[imageIndex], 3, count, first, 1);
    }

    void drawning() @trusted
    {
        VkSubmitInfo smbInfo;

        VkSemaphore[] waitSemaphores = [imgAval];
        VkPipelineStageFlags[] waitStages = [VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT];
        smbInfo.waitSemaphoreCount = 1;
        smbInfo.pWaitSemaphores = waitSemaphores.ptr;
        smbInfo.pWaitDstStageMask = waitStages.ptr;

        smbInfo.commandBufferCount = 1;
        smbInfo.pCommandBuffers = &cmdBuff[imageIndex];

        VkSemaphore[] signalSemaphores = [renFinl];
        smbInfo.signalSemaphoreCount = 1;
        smbInfo.pSignalSemaphores = signalSemaphores.ptr;

        vkCmdEndRenderPass(cmdBuff[imageIndex]);
        vkEndCommandBuffer(cmdBuff[imageIndex]);

        vkEnforce(vkQueueSubmit(queueGraph.handle, 1, &smbInfo, flFence));

        VkPresentInfoKHR prsInfo;

        prsInfo.waitSemaphoreCount = 1;
        prsInfo.pWaitSemaphores = signalSemaphores.ptr;

        VkSwapchainKHR[] swapChains = [surface.swapchain];
        prsInfo.swapchainCount = 1;
        prsInfo.pSwapchains = swapChains.ptr;
        prsInfo.pImageIndices = &imageIndex;

        vkQueuePresentKHR(queuePresent.handle, &prsInfo);
        vkDeviceWaitIdle(context.device.logical);
    }

    IShaderManip createShader(StageType stage)
    {
        return new VulkanShaderManip(context.device.logical, stage);
    }

    IShaderProgram createShaderProgram()
    {
        auto prg = new VulkanShaderProgram(
            context,
            surface,
            vport,
            scissor,
            bInfo,
            renderPass
        );

        //programs ~= prg;

        return prg;
    }
}
