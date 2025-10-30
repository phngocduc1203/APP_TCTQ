<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('habit_completions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('habit_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->date('completed_date');
            $table->integer('xp_earned')->default(0);
            $table->timestamps();
            
            // Đảm bảo mỗi habit chỉ complete 1 lần mỗi ngày
            $table->unique(['habit_id', 'completed_date']);
            
            // Index để query nhanh
            $table->index(['user_id', 'completed_date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('habit_completions');
    }
};