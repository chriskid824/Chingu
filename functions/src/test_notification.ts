import { getNotificationContent, NotificationType, ExperimentGroup, getExperimentGroup, getHashCode } from './notification_content';

function assert(condition: boolean, message: string) {
    if (!condition) {
        throw new Error(`Assertion failed: ${message}`);
    }
    console.log(`PASS: ${message}`);
}

function test() {
    console.log("Starting Notification A/B Test Verification...");

    const users = ["test", "user1", "user2", "user3", "chris", "demo"];
    const variants: string[] = [];
    const controls: string[] = [];

    users.forEach(u => {
        const hash = getHashCode(u);
        const group = getExperimentGroup(u);
        console.log(`User: ${u}, Hash: ${hash}, Group: ${group}`);
        if (group === ExperimentGroup.Variant) variants.push(u);
        else controls.push(u);
    });

    if (controls.length === 0 || variants.length === 0) {
        console.warn("Could not find both control and variant users in the sample list.");
        return;
    }

    const userControl = controls[0];
    const userVariant = variants[0];

    console.log(`Selected Control User: ${userControl}`);
    console.log(`Selected Variant User: ${userVariant}`);

    // Test Match Notification
    const matchControl = getNotificationContent(userControl, NotificationType.Match, { partnerName: 'Alice' });
    const matchVariant = getNotificationContent(userVariant, NotificationType.Match, { partnerName: 'Alice' });

    assert(matchControl.title === '新配對', 'Match Control Title');
    assert(matchControl.body.includes('配對成功。'), 'Match Control Body');

    assert(matchVariant.title === '配對成功！🎉', 'Match Variant Title');
    assert(matchVariant.body.includes('現在就去打個招呼吧！👋'), 'Match Variant Body');

    // Test Event Reminder
    const eventControl = getNotificationContent(userControl, NotificationType.Event, { eventTitle: 'Dinner', daysLeft: 2 });
    const eventVariant = getNotificationContent(userVariant, NotificationType.Event, { eventTitle: 'Dinner', daysLeft: 2 });

    assert(eventControl.title === '活動提醒', 'Event Control Title');
    assert(eventControl.body.includes('您即將參加的活動'), 'Event Control Body');

    assert(eventVariant.title === '活動提醒 🍽️', 'Event Variant Title');
    assert(eventVariant.body.includes('準備好了嗎？'), 'Event Variant Body');

    console.log("All tests passed!");
}

test();
