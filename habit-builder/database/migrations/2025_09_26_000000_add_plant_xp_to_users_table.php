<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
   public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        if (!Schema::hasColumn('users', 'plant_xp')) {
            $table->integer('plant_xp')->default(0)->after('some_existing_column');
        }

        if (!Schema::hasColumn('users', 'plant_last_update')) {
            $table->datetime('plant_last_update')->nullable()->after('plant_xp');
        }

        if (!Schema::hasColumn('users', 'plant_status')) {
            $table->enum('plant_status', ['healthy', 'wilted', 'dead'])
                ->default('healthy')
                ->after('plant_last_update');
        }
    });
}


    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['plant_last_update', 'plant_status']);
        });
    }
};