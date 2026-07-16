-- RemoveEventHostForeignKey
-- Remove the EventHost foreign key relationship from Event.hosterId
-- This allows events to be created by users not in the system

ALTER TABLE "Event" DROP CONSTRAINT "Event_hosterId_fkey";
