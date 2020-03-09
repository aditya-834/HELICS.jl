
include("init.jl")

@testset "Filter Type Tests registration" begin

    broker = createBroker(2)
    fFed, fedinfo1 = createMessageFederate(1, "filter")
    mFed, fedinfo2 = createMessageFederate(1, "message")

    h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "")

    f1 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter1")
    h.helicsFilterAddSourceTarget(f1, "port1")

    f2 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter2")
    h.helicsFilterAddDestinationTarget(f2, "port2")

    @test f1 != f2

    ep1 = h.helicsFederateRegisterEndpoint(fFed, "fout", "")

    f3 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "c4")
    h.helicsFilterAddSourceTarget(f3, "Testfilter/fout")

    f1_b = h.helicsFederateGetFilter(fFed, "filter1")
    tmp = h.helicsFilterGetName(f1_b)
    @test tmp == "Testfilter/filter1"

    f1_c = h.helicsFederateGetFilterByIndex(fFed, 2)
    tmp = h.helicsFilterGetName(f1_c)
    @test tmp == "Testfilter/c4"

    @test_throws HELICS.Utils.HelicsErrorInvalidArgument f1_n = h.helicsFederateGetFilterByIndex(fFed, -2)

    h.helicsFederateEnterExecutingModeAsync(fFed)
    h.helicsFederateEnterExecutingMode(mFed)
    h.helicsFederateEnterExecutingModeComplete(fFed)
    h.helicsFederateFinalizeAsync(mFed)
    h.helicsFederateFinalize(fFed)
    h.helicsFederateFinalizeComplete(mFed)

    state = h.helicsFederateGetState(fFed)
    @test state == h.HELICS_STATE_FINALIZE

    destroyFederate(fFed, fedinfo1)
    destroyFederate(mFed, fedinfo2)
    destroyBroker(broker)


end


@testset "Filter Type Tests info" begin

    broker = createBroker(2)
    fFed, fedinfo1 = createMessageFederate(1, "filter")
    mFed, fedinfo2 = createMessageFederate(1, "message")

    p1 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    p2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "")

    h.helicsEndpointSetInfo(p1, "p1_test")
    h.helicsEndpointSetInfo(p2, "p2_test")

    f1 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter1")
    h.helicsFilterAddSourceTarget(f1, "port1")
    h.helicsFilterSetInfo(f1, "f1_test")

    f2 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter2")
    h.helicsFilterAddDestinationTarget(f2, "port2")
    h.helicsFilterSetInfo(f2, "f2_test")

    ep1 = h.helicsFederateRegisterEndpoint(fFed, "fout", "")
    h.helicsEndpointSetInfo(ep1, "ep1_test")
    f3 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "c4")
    h.helicsFilterAddSourceTarget(f3, "filter0/fout")
    h.helicsFilterSetInfo(f3, "f3_test")

    @test h.helicsEndpointGetInfo(p1) == "p1_test"
    @test h.helicsEndpointGetInfo(p2) == "p2_test"
    @test h.helicsEndpointGetInfo(ep1) == "ep1_test"

    @test h.helicsFilterGetInfo(f1) == "f1_test"
    @test h.helicsFilterGetInfo(f2) == "f2_test"
    @test h.helicsFilterGetInfo(f3) == "f3_test"

    h.helicsFederateEnterExecutingModeAsync(fFed)
    h.helicsFederateEnterExecutingMode(mFed)
    h.helicsFederateEnterExecutingModeComplete(fFed)

    h.helicsFederateFinalizeAsync(mFed)
    h.helicsFederateFinalize(fFed)
    h.helicsFederateFinalizeComplete(mFed)

    destroyFederate(fFed, fedinfo1)
    destroyFederate(mFed, fedinfo2)
    destroyBroker(broker)

end


@testset "Filter Type Tests message filter function" begin

    broker = createBroker(2)
    fFed, fedinfo1 = createMessageFederate(1, "filter")
    mFed, fedinfo2 = createMessageFederate(1, "message")

    h.helicsFederateSetFlagOption(mFed, h.HELICS_FLAG_IGNORE_TIME_MISMATCH_WARNINGS, true)
    p1 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    p2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "")

    f1 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_DELAY, "filter1")
    h.helicsFilterAddSourceTarget(f1, "port1")
    h.helicsFilterSet(f1, "delay", 2.5)

    h.helicsFederateEnterExecutingModeAsync(fFed)
    h.helicsFederateEnterExecutingMode(mFed)
    h.helicsFederateEnterExecutingModeComplete(fFed)

    state = h.helicsFederateGetState(fFed)
    @test state == h.HELICS_STATE_EXECUTION
    data = repeat('a', 500)
    h.helicsEndpointSendMessageRaw(p1, "port2", data)

    h.helicsFederateRequestTimeAsync(mFed, 1.0)
    h.helicsFederateRequestTime(fFed, 1.0)
    h.helicsFederateRequestTimeComplete(mFed)

    @test h.helicsFederateHasMessage(mFed) == false

    h.helicsFederateRequestTimeAsync(mFed, 2.0)
    h.helicsFederateRequestTime(fFed, 2.0)
    h.helicsFederateRequestTimeComplete(mFed)
    @test h.helicsEndpointHasMessage(p2) == false

    h.helicsFederateRequestTimeAsync(fFed, 3.0)
    h.helicsFederateRequestTime(mFed, 3.0)

    @test h.helicsEndpointHasMessage(p2) == true

    m2 = h.helicsEndpointGetMessage(p2)
    @test unsafe_string(m2.source) == "port1"
    @test unsafe_string(m2.original_source) == "port1"
    @test unsafe_string(m2.dest) == "port2"
    @test m2.length == length(data)
    @test m2.time == 2.5

    h.helicsFederateRequestTime(mFed, 3.0)
    h.helicsFederateRequestTimeComplete(fFed)
    h.helicsFederateFinalizeAsync(mFed)
    h.helicsFederateFinalize(fFed)
    h.helicsFederateFinalizeComplete(mFed)
    state = h.helicsFederateGetState(fFed)
    @test state == h.HELICS_STATE_FINALIZE

    destroyFederate(fFed, fedinfo1)
    destroyFederate(mFed, fedinfo2)
    destroyBroker(broker)

end


@testset "Filter test types function mObj" begin

    broker = createBroker(2)
    fFed, fedinfo1 = createMessageFederate(1, "filter")
    mFed, fedinfo2 = createMessageFederate(1, "message")

    h.helicsFederateSetFlagOption(mFed, h.HELICS_FLAG_IGNORE_TIME_MISMATCH_WARNINGS, true)
    p1 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    p2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "")

    f1 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_DELAY, "filter1")
    h.helicsFilterAddSourceTarget(f1, "port1")
    h.helicsFilterSet(f1, "delay", 2.5,)

    h.helicsFederateEnterExecutingModeAsync(fFed)
    h.helicsFederateEnterExecutingMode(mFed)
    h.helicsFederateEnterExecutingModeComplete(fFed)

    state = h.helicsFederateGetState(fFed)
    @test state == h.HELICS_STATE_EXECUTION

    data = repeat('a', 500)
    h.helicsEndpointSendMessageRaw(p1, "port2", data)

    h.helicsFederateRequestTimeAsync(mFed, 1.0)
    h.helicsFederateRequestTime(fFed, 1.0)
    h.helicsFederateRequestTimeComplete(mFed)

    res = h.helicsFederateHasMessage(mFed)
    @test res == false

    h.helicsFederateRequestTimeAsync(mFed, 2.0)
    h.helicsFederateRequestTime(fFed, 2.0)
    h.helicsFederateRequestTimeComplete(mFed)
    @test h.helicsEndpointHasMessage(p2) == false

    h.helicsFederateRequestTimeAsync(fFed, 3.0)
    h.helicsFederateRequestTime(mFed, 3.0)

    @test h.helicsEndpointHasMessage(p2) == true

    m2 = h.helicsEndpointGetMessageObject(p2)
    @test h.helicsMessageGetSource(m2) == "port1"
    @test h.helicsMessageGetOriginalSource(m2) == "port1"
    @test h.helicsMessageGetDestination(m2) == "port2"
    @test h.helicsMessageGetRawDataSize(m2) == length(data)
    @test h.helicsMessageGetTime(m2) == 2.5

    h.helicsFederateRequestTime(mFed, 3.0)
    h.helicsFederateRequestTimeComplete(fFed)
    h.helicsFederateFinalizeAsync(mFed)
    h.helicsFederateFinalize(fFed)
    h.helicsFederateFinalizeComplete(mFed)
    state = h.helicsFederateGetState(fFed)
    @test state == h.HELICS_STATE_FINALIZE

    destroyFederate(fFed, fedinfo1)
    destroyFederate(mFed, fedinfo2)
    destroyBroker(broker)

end

@testset "Filter test types function two stage" begin

    broker = createBroker(3)
    fFed, fedinfo1 = createMessageFederate(1, "filter")
    fFed2, fedinfo2 = createMessageFederate(1, "filter2")
    mFed, fedinfo3 = createMessageFederate(1, "message")

    p1 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    p2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "")

    f1 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_DELAY, "filter1")
    h.helicsFilterAddSourceTarget(f1, "port1")
    h.helicsFilterSet(f1, "delay", 1.25)

    f2 = h.helicsFederateRegisterFilter(fFed2, h.HELICS_FILTER_TYPE_DELAY, "filter2")
    h.helicsFilterAddSourceTarget(f2, "port1")
    h.helicsFilterSet(f2, "delay", 1.25)

    h.helicsFederateEnterExecutingModeAsync(fFed)
    h.helicsFederateEnterExecutingModeAsync(fFed2)
    h.helicsFederateEnterExecutingMode(mFed)
    h.helicsFederateEnterExecutingModeComplete(fFed)
    h.helicsFederateEnterExecutingModeComplete(fFed2)

    state = h.helicsFederateGetState(fFed)
    @test state == h.HELICS_STATE_EXECUTION
    data = repeat('a', 500)
    h.helicsEndpointSendMessageRaw(p1, "port2", data)

    h.helicsFederateRequestTimeAsync(mFed, .0)
    h.helicsFederateRequestTimeAsync(fFed, 1.0)
    h.helicsFederateRequestTime(fFed2, 1.0)
    h.helicsFederateRequestTimeComplete(mFed)
    h.helicsFederateRequestTimeComplete(fFed)
    @test h.helicsFederateHasMessage(mFed) == false

    h.helicsFederateRequestTimeAsync(mFed, .0)
    h.helicsFederateRequestTimeAsync(fFed2, 2.0)
    h.helicsFederateRequestTime(fFed, 2.0)
    h.helicsFederateRequestTimeComplete(mFed)
    h.helicsFederateRequestTimeComplete(fFed2)
    @test h.helicsEndpointHasMessage(p2) == false

    h.helicsFederateRequestTimeAsync(fFed, 3.0)
    h.helicsFederateRequestTimeAsync(fFed2, 3.0)
    h.helicsFederateRequestTime(mFed, 3.0)
    @test h.helicsEndpointHasMessage(p2) == true

    m2 = h.helicsEndpointGetMessage(p2)
    @test unsafe_string(m2.source) == "port1"
    @test unsafe_string(m2.original_source) == "port1"
    @test unsafe_string(m2.dest) == "port2"
    @test m2.length == length(data)
    @test m2.time == 2.5

    h.helicsFederateRequestTimeComplete(fFed)
    h.helicsFederateRequestTimeComplete(fFed2)
    h.helicsFederateFinalizeAsync(mFed)
    h.helicsFederateFinalizeAsync(fFed)
    h.helicsFederateFinalize(fFed2)
    h.helicsFederateFinalizeComplete(mFed)
    h.helicsFederateFinalizeComplete(fFed)
    state = h.helicsFederateGetState(fFed)
    @test state == h.HELICS_STATE_FINALIZE


    destroyFederate(fFed, fedinfo1)
    destroyFederate(fFed2, fedinfo2)
    destroyFederate(mFed, fedinfo3)
    destroyBroker(broker)

end

@testset "Filter test types function2" begin

    broker = createBroker(2)
    fFed, fedinfo1 = createMessageFederate(1, "filter")
    mFed, fedinfo2 = createMessageFederate(1, "message")

    p1 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    p2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "")

    f1 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_DELAY, "filter1")
    h.helicsFilterAddSourceTarget(f1, "port1")
    h.helicsFilterSet(f1, "delay", 2.5)

    f2 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_DELAY, "filter2")
    h.helicsFilterAddSourceTarget(f2, "port2")
    h.helicsFilterSet(f2, "delay", 2.5)
    # this is expected to fail since a regular filter doesn't have a delivery endpoint
    @test_throws h.Utils.HelicsErrorInvalidObject h.helicsFilterAddDeliveryEndpoint(f2, "port1")

    h.helicsFederateEnterExecutingModeAsync(fFed)
    h.helicsFederateEnterExecutingMode(mFed)
    h.helicsFederateEnterExecutingModeComplete(fFed)

    state = h.helicsFederateGetState(fFed)
    @test state == h.HELICS_STATE_EXECUTION

    data = repeat('a', 500)
    h.helicsEndpointSendMessageRaw(p1, "port2", data)

    h.helicsFederateRequestTimeAsync(mFed, 1.0)
    h.helicsFederateRequestTime(fFed, 1.0)
    h.helicsFederateRequestTimeComplete(mFed)

    res = h.helicsFederateHasMessage(mFed)
    @test res == false

    h.helicsEndpointSendMessageRaw(p2, "port1", data)
    h.helicsFederateRequestTimeAsync(mFed, 2.0)
    h.helicsFederateRequestTime(fFed, 2.0)
    h.helicsFederateRequestTimeComplete(mFed)
    @test h.helicsEndpointHasMessage(p2) == false
    # there may be something wrong here yet but this test isn't the one to find it and
    # this may prevent spurious errors for now.
    # std::this_thread::yield()
    h.helicsFederateRequestTime(mFed, 3.0)

    @test h.helicsEndpointHasMessage(p2) == true

    m2 = h.helicsEndpointGetMessage(p2)
    @test unsafe_string(m2.source) == "port1"
    @test unsafe_string(m2.original_source) == "port1"
    @test unsafe_string(m2.dest) == "port2"
    @test m2.length == length(data)
    @test m2.time == 2.5

    @test h.helicsEndpointHasMessage(p1) == false

    h.helicsFederateRequestTime(mFed, 4.0)
    @test h.helicsEndpointHasMessage(p1) == true
    h.helicsFederateFinalizeAsync(mFed)
    h.helicsFederateFinalize(fFed)
    h.helicsFederateFinalizeComplete(mFed)
    state = h.helicsFederateGetState(fFed)
    @test state == h.HELICS_STATE_FINALIZE

    destroyFederate(fFed, fedinfo1)
    destroyFederate(mFed, fedinfo2)
    destroyBroker(broker)
end

@testset "Filter test types function3" begin

    # broker = createBroker(2)
    # fFed, fedinfo = createMessageFederate(1, "filter")
    # mFed, fedinfo = createMessageFederate(1, "message")

    # p1 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port1", "")
    # p2 = h.helicsFederateRegisterGlobalEndpoint(mFed, "port2", "random")

    # f1 = h.helicsFederateRegisterGlobalFilter(fFed, h.HELICS_FILTER_TYPE_CUSTOM, "filter1")
    # h.helicsFilterAddSourceTarget(f1, "port1")
    # f2 = h.helicsFederateRegisterGlobalFilter(fFed, h.HELICS_FILTER_TYPE_DELAY, "filter2")
    # h.helicsFilterAddSourceTarget(f2, "port1")

    # h.helicsFederateRegisterEndpoint(fFed, "fout", "")
    # f3 = h.helicsFederateRegisterFilter(fFed, h.HELICS_FILTER_TYPE_RANDOM_DELAY, "filter3")
    # h.helicsFilterAddSourceTarget(f3, "filter0/fout")

    # h.helicsFilterSet(f2, "delay", 2.5)

    # h.helicsFederateEnterExecutingModeAsync(fFed)
    # h.helicsFederateEnterExecutingMode(mFed)
    # h.helicsFederateEnterExecutingModeComplete(fFed)

    # state = h.helicsFederateGetState(fFed)
    # @test state == h.HELICS_STATE_EXECUTION

    # data = "hello world"
    # h.helicsEndpointSendMessageRaw(p1, "port2", data)

    # h.helicsFederateRequestTimeAsync(mFed, 1.0)
    # h.helicsFederateRequestTime(fFed, 1.0)
    # h.helicsFederateRequestTimeComplete(mFed)

    # @test h.helicsFederateHasMessage(mFed) == false

    # h.helicsEndpointSendMessageRaw(p2, "port1", data)
    # h.helicsFederateRequestTimeAsync(mFed, 2.0)
    # println("############### Before fFed")
    # h.helicsFederateRequestTime(fFed, 2.0)
    # println("############### After fFed")
    # h.helicsFederateRequestTimeComplete(mFed)
    # @test h.helicsEndpointHasMessage(p2) == false
    # # there may be something wrong here yet but this test isn't the one to find it and
    # # this may prevent spurious errors for now.
    # # std::this_thread::yield()
    # h.helicsFederateRequestTimeAsync(mFed, 3.0)
    # h.helicsFederateRequestTime(fFed, 3.0)
    # h.helicsFederateRequestTimeComplete(mFed)

    # @test h.helicsEndpointHasMessage(p2)

    # m2 = h.helicsEndpointGetMessage(p2)
    # @test unsafe_string(m2.source) == "port1"
    # @test unsafe_string(m2.original_source) == "port1"
    # @test unsafe_string(m2.dest) == "port2"
    # @test m2.length == length(data)
    # @test m2.time == 2.5

    # @test h.helicsEndpointHasMessage(p1) == true
    # h.helicsFederateFinalize(mFed)
    # h.helicsFederateFinalize(fFed)
    # state = h.helicsFederateGetState(fFed)
    # @test state == h.HELICS_STATE_FINALIZE

end

@testset "Filter test types clone test" begin

    # broker = createBroker(3)
    # sFed, fedinfo1 = createMessageFederate(1, "source")
    # dFed, fedinfo2 = createMessageFederate(1, "dest")
    # dcFed, fedinfo3 = createMessageFederate(1, "dest_clone")
    #
    # p1 = h.helicsFederateRegisterGlobalEndpoint(sFed, "src", "")
    # p2 = h.helicsFederateRegisterGlobalEndpoint(dFed, "dest", "")
    # p3 = h.helicsFederateRegisterGlobalEndpoint(dcFed, "cm", "")
    #
    # f1 = h.helicsFederateRegisterCloningFilter(dcFed, "")
    # h.helicsFilterAddDeliveryEndpoint(f1, "cm")
    # h.helicsFilterAddSourceTarget(f1, "src")
    #
    # h.helicsFederateEnterExecutingModeAsync(sFed)
    # h.helicsFederateEnterExecutingModeAsync(dcFed)
    # h.helicsFederateEnterExecutingMode(dFed)
    # h.helicsFederateEnterExecutingModeComplete(sFed)
    # h.helicsFederateEnterExecutingModeComplete(dcFed)
    #
    # state = h.helicsFederateGetState(sFed)
    # @test state == h.HELICS_STATE_EXECUTION
    # state = h.helicsFederateGetState(dcFed)
    # @test state == h.HELICS_STATE_EXECUTION
    # state = h.helicsFederateGetState(dFed)
    # @test state == h.HELICS_STATE_EXECUTION
    #
    # data = repeat('a', 500)
    # h.helicsEndpointSendMessageRaw(p1, "dest", data)
    #
    # h.helicsFederateRequestTimeAsync(sFed, 1.0)
    # h.helicsFederateRequestTimeAsync(dcFed, 1.0)
    # h.helicsFederateRequestTime(dFed, 1.0)
    # h.helicsFederateRequestTimeComplete(sFed)
    # h.helicsFederateRequestTimeComplete(dcFed)
    #
    # @test h.helicsFederateHasMessage(dFed)
    #
    # m2 = h.helicsEndpointGetMessage(p2)
    # @test unsafe_string(m2.source) == "src"
    # @test unsafe_string(m2.original_source) == "src"
    # @test unsafe_string(m2.dest) == "dest"
    # @test m2.length == length(data)
    #
    # @test h.helicsFederateHasMessage(dcFed)
    #
    # m2 = h.helicsEndpointGetMessage(p3)
    # @test unsafe_string(m2.source) =="src"
    # @test unsafe_string(m2.original_source) =="src"
    # @test unsafe_string(m2.dest) =="cm"
    # @test unsafe_string(m2.original_dest) =="dest"
    # @test m2.length == length(data)
    #
    # h.helicsFederateFinalizeAsync(sFed)
    # h.helicsFederateFinalizeAsync(dFed)
    # h.helicsFederateFinalize(dcFed)
    # h.helicsFederateFinalizeComplete(sFed)
    # h.helicsFederateFinalizeComplete(dFed)
    # state = h.helicsFederateGetState(sFed)
    # @test state == h.HELICS_STATE_FINALIZE
    #
    # destroyFederate(sFed, fedinfo1)
    # destroyFederate(dFed, fedinfo2)
    # destroyFederate(dcFed, fedinfo3)
    # destroyBroker(broker)

end
