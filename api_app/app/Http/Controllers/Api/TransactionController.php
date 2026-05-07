<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    /**
     * GET /api/transactions
     * List semua transaksi milik user yang login.
     * Query params: ?type=income|expense
     */
    public function index(Request $request)
    {
        $query = $request->user()->transactions()->orderBy('transaction_date', 'desc')->orderBy('created_at', 'desc');

        if ($request->has('type') && in_array($request->type, ['income', 'expense'])) {
            $query->where('type', $request->type);
        }

        $transactions = $query->get();

        return response()->json([
            'message' => 'Data transaksi berhasil diambil',
            'data' => $transactions,
        ]);
    }

    /**
     * POST /api/transactions
     * Tambah transaksi baru.
     */
    public function store(Request $request)
    {
        $request->validate([
            'type' => 'required|in:income,expense',
            'amount' => 'required|numeric|min:1',
            'category' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
            'transaction_date' => 'required|date',
        ]);

        $transaction = $request->user()->transactions()->create([
            'type' => $request->type,
            'amount' => $request->amount,
            'category' => $request->category,
            'description' => $request->description,
            'transaction_date' => $request->transaction_date,
        ]);

        return response()->json([
            'message' => 'Transaksi berhasil ditambahkan',
            'data' => $transaction,
        ], 201);
    }

    /**
     * GET /api/transactions/{id}
     * Detail satu transaksi.
     */
    public function show(Request $request, string $id)
    {
        $transaction = $request->user()->transactions()->find($id);

        if (!$transaction) {
            return response()->json([
                'message' => 'Transaksi tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'message' => 'Detail transaksi',
            'data' => $transaction,
        ]);
    }

    /**
     * PUT /api/transactions/{id}
     * Update transaksi.
     */
    public function update(Request $request, string $id)
    {
        $transaction = $request->user()->transactions()->find($id);

        if (!$transaction) {
            return response()->json([
                'message' => 'Transaksi tidak ditemukan',
            ], 404);
        }

        $request->validate([
            'type' => 'required|in:income,expense',
            'amount' => 'required|numeric|min:1',
            'category' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
            'transaction_date' => 'required|date',
        ]);

        $transaction->update([
            'type' => $request->type,
            'amount' => $request->amount,
            'category' => $request->category,
            'description' => $request->description,
            'transaction_date' => $request->transaction_date,
        ]);

        return response()->json([
            'message' => 'Transaksi berhasil diperbarui',
            'data' => $transaction,
        ]);
    }

    /**
     * DELETE /api/transactions/{id}
     * Hapus transaksi.
     */
    public function destroy(Request $request, string $id)
    {
        $transaction = $request->user()->transactions()->find($id);

        if (!$transaction) {
            return response()->json([
                'message' => 'Transaksi tidak ditemukan',
            ], 404);
        }

        $transaction->delete();

        return response()->json([
            'message' => 'Transaksi berhasil dihapus',
        ]);
    }

    /**
     * GET /api/transactions/summary
     * Ringkasan total income, expense, dan balance.
     */
    public function summary(Request $request)
    {
        $userId = $request->user()->id;

        $totalIncome = Transaction::where('user_id', $userId)
            ->where('type', 'income')
            ->sum('amount');

        $totalExpense = Transaction::where('user_id', $userId)
            ->where('type', 'expense')
            ->sum('amount');

        $balance = $totalIncome - $totalExpense;

        return response()->json([
            'message' => 'Ringkasan transaksi',
            'data' => [
                'total_income' => (float) $totalIncome,
                'total_expense' => (float) $totalExpense,
                'balance' => (float) $balance,
            ],
        ]);
    }
}
