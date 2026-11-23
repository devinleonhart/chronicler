CREATE TABLE "Character" (
	"id" serial PRIMARY KEY NOT NULL,
	"createdAt" timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updatedAt" timestamp(3) NOT NULL,
	"name" varchar(255) NOT NULL,
	"birthDate" varchar(10) NOT NULL,
	"deathDate" varchar(10)
);
--> statement-breakpoint
CREATE TABLE "CharacterGroup" (
	"characterId" integer NOT NULL,
	"groupId" integer NOT NULL,
	CONSTRAINT "CharacterGroup_pkey" PRIMARY KEY("characterId","groupId")
);
--> statement-breakpoint
CREATE TABLE "Event" (
	"id" serial PRIMARY KEY NOT NULL,
	"createdAt" timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updatedAt" timestamp(3) NOT NULL,
	"name" varchar(255) NOT NULL,
	"startDate" varchar(10) NOT NULL,
	"endDate" varchar(10),
	"isCurrentDay" boolean DEFAULT false NOT NULL
);
--> statement-breakpoint
CREATE TABLE "EventCharacter" (
	"eventId" integer NOT NULL,
	"characterId" integer NOT NULL,
	CONSTRAINT "EventCharacter_pkey" PRIMARY KEY("eventId","characterId")
);
--> statement-breakpoint
CREATE TABLE "Group" (
	"id" serial PRIMARY KEY NOT NULL,
	"createdAt" timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updatedAt" timestamp(3) NOT NULL,
	"name" varchar(255) NOT NULL,
	"description" text
);
--> statement-breakpoint
CREATE TABLE "UniverseSettings" (
	"id" serial PRIMARY KEY NOT NULL,
	"createdAt" timestamp(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
	"updatedAt" timestamp(3) NOT NULL,
	"name" varchar(255) DEFAULT 'My Universe' NOT NULL,
	"startDate" varchar(10) NOT NULL,
	"endDate" varchar(10) NOT NULL,
	"currentDay" varchar(10) NOT NULL
);
--> statement-breakpoint
ALTER TABLE "CharacterGroup" ADD CONSTRAINT "CharacterGroup_characterId_fkey" FOREIGN KEY ("characterId") REFERENCES "public"."Character"("id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "CharacterGroup" ADD CONSTRAINT "CharacterGroup_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "public"."Group"("id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "EventCharacter" ADD CONSTRAINT "EventCharacter_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "public"."Event"("id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "EventCharacter" ADD CONSTRAINT "EventCharacter_characterId_fkey" FOREIGN KEY ("characterId") REFERENCES "public"."Character"("id") ON DELETE cascade ON UPDATE cascade;