
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

end