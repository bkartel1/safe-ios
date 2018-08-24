//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public class MockEventPublisher: EventPublisher {

    private var filteredEventTypes = [String]()
    private var expectedToPublish = [DomainEvent.Type]()
    private var actuallyPublished = [DomainEvent.Type]()

    public func addFilter(_ event: Any.Type) {
        filteredEventTypes.append(String(reflecting: event))
    }

    public func expectToPublish(_ event: DomainEvent.Type) {
        expectedToPublish.append(event)
    }

    public func publishedWhatWasExpected() -> Bool {
        return actuallyPublished.map { String(reflecting: $0) } == expectedToPublish.map { String(reflecting: $0) }
    }

    override public func publish(_ event: DomainEvent) {
        guard filteredEventTypes.isEmpty || filteredEventTypes.contains(String(reflecting: type(of: event))) else {
            return
        }
        super.publish(event)
        actuallyPublished.append(type(of: event))
    }

    private var expected_reset = [String]()
    private var actual_reset = [String]()

    public func expect_reset() {
        expected_reset.append("reset()")
    }

    public override func reset() {
        actual_reset.append(#function)
    }

    public func verify() -> Bool {
        return actual_reset == expected_reset
    }

}